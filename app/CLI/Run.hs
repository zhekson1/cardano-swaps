{-# LANGUAGE TemplateHaskell #-}

module CLI.Run
(
  runCommand
) where

import Data.Aeson
import Data.Aeson.Encode.Pretty
import qualified Data.ByteString.Lazy as BL
import Data.ByteString (ByteString)
import Data.FileEmbed

import CardanoSwaps
import CLI.Types
import CLI.Query

blueprintsFile :: ByteString
blueprintsFile = $(embedFile "aiken/plutus.json")

blueprints :: Blueprints
blueprints = parseBlueprints $ BL.fromStrict blueprintsFile

runCommand :: Command -> IO ()
runCommand cmd = case cmd of
  ExportScript script file -> runExportScriptCmd script file
  CreateDatum d file -> runCreateDatum d file
  CreateSwapRedeemer r file -> writeData file r
  CreateBeaconRedeemer r file -> writeData file r
  GenerateBeaconFullName offerCfg askCfg output -> 
    runGenerateBeaconFullName offerCfg askCfg output
  QueryBeacons query -> runQuery query

runExportScriptCmd :: Script -> FilePath -> IO ()
runExportScriptCmd script file = do
  let script' = case script of
        SwapScript -> genSwapScript blueprints
        BeaconPolicy cfg -> genBeaconPolicy cfg blueprints
  res <- writeScript file script'
  case res of
    Right _ -> return ()
    Left err -> putStrLn $ "There was an error: " <> show err

runCreateDatum :: SwapDatumInfo -> FilePath -> IO ()
runCreateDatum (SwapDatumInfo offerConfig askConfig swapPrice') file = do
  let beaconSym = genBeaconCurrencySymbol offerConfig blueprints
  writeData file $ 
    SwapDatum 
      { beaconId = beaconSym
      , beaconName = genBeaconName askConfig
      , offerId = assetId offerConfig
      , offerName = assetName offerConfig
      , askId = assetId askConfig
      , askName = assetName askConfig
      , swapPrice = swapPrice'
      }

runGenerateBeaconFullName :: AssetConfig -> AssetConfig -> Output -> IO ()
runGenerateBeaconFullName offerCfg askCfg output = do
  let beacon = show (genBeaconCurrencySymbol offerCfg blueprints) 
            <> "." 
            <> drop 2 (show $ genBeaconName askCfg)
  case output of
    Stdout -> putStr beacon
    File file -> writeFile file beacon

runQuery :: Query -> IO ()
runQuery query = case query of
  QueryAllSwapsByTradingPair network api offerCfg askCfg output -> do
    let beaconSym = genBeaconCurrencySymbol offerCfg blueprints
        beaconTokName = genBeaconName askCfg
    runQueryAllSwapsByTradingPair network api beaconSym beaconTokName offerCfg >>= toOutput output

  QueryOwnSwapsByTradingPair network api addr offerCfg askCfg output -> do
    let beaconSym = genBeaconCurrencySymbol offerCfg blueprints
        beaconTokName = genBeaconName askCfg
    runQueryOwnSwapsByTradingPair network api addr beaconSym beaconTokName >>= toOutput output

  QueryAllSwapsByOffer offerCfg output -> do
    let beaconSym = genBeaconCurrencySymbol offerCfg blueprints
    runQueryAllSwapsByOffer beaconSym >>= toOutput output

  QueryOwnSwapsByOffer addr offerCfg output -> do
    let beaconSym = genBeaconCurrencySymbol offerCfg blueprints
    runQueryOwnSwapsByOffer addr beaconSym >>= toOutput output

  QueryOwnSwaps network api addr output -> do
    runQueryOwnSwaps network api addr >>= toOutput output

-------------------------------------------------
-- Helper Functions
-------------------------------------------------
toOutput :: (ToJSON a) => Output -> a -> IO ()
toOutput output xs = case output of
  Stdout -> BL.putStr $ encode xs
  File file -> BL.writeFile file $ encodePretty xs