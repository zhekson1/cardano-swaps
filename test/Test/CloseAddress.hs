{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE NamedFieldPuns      #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeFamilies        #-}
{-# LANGUAGE TypeOperators       #-}
{-# LANGUAGE NumericUnderscores  #-}
{-# LANGUAGE DeriveAnyClass      #-}
{-# LANGUAGE DeriveGeneric       #-}

module Test.CloseAddress
(
  tests,
  testTrace
) where

import Prelude (IO)
import Control.Monad (void)
import Control.Lens hiding (from)
import PlutusTx.Prelude
import Plutus.Trace
import Wallet.Emulator.Wallet
import Plutus.Contract.Test as Test
import Test.Tasty
import Ledger.Ada (lovelaceValueOf)
import Data.Default
import Plutus.V2.Ledger.Api
import Ledger.Address

import Test.Common

import CardanoSwaps (beaconSymbol,swapValidatorHash)

-------------------------------------------------
-- Close Scenarios
-------------------------------------------------
closeAddressAndRemoveAllUtxos :: EmulatorTrace ()
closeAddressAndRemoveAllUtxos = do
  h1 <- activateContractWallet (knownWallet 1) endpoints

  let beaconSwapConfig = swapConfig1
      addressSwapConfig = swapConfig1

      beaconSymbol' = beaconSymbol $ convert2SwapConfig beaconSwapConfig

      swapDatum' = SwapDatum'
        { swapPrice' = unsafeRatio 2 1
        , swapBeacon' = Just beaconSymbol'
        }

      swapAddress = Address 
        (ScriptCredential $ swapValidatorHash $ convert2SwapConfig addressSwapConfig)
        (Just $ StakingHash 
              $ PubKeyCredential 
              $ unPaymentPubKeyHash 
              $ mockWalletPaymentPubKeyHash 
              $ knownWallet 1)

  callEndpoint @"create-live-swap-address" h1 $
    CreateLiveSwapAddressParams
      { beaconsMinted = [(adaToken,1)]
      , useMintRedeemer = True
      , createLiveBeaconSwapConfig = beaconSwapConfig
      , createLiveAddressSwapConfig = addressSwapConfig
      , createLiveAddress = swapAddress
      , createLiveRefScript = Proper
      , createLiveRefScriptUtxo =
          ( Just swapDatum'
          , singleton beaconSymbol' adaToken 1 <> refScriptDeposit
          )
      , createLiveInitialPositions =
          [ ( Just swapDatum'
            , lovelaceValueOf 100_000_000
            )
          ]
      , createLiveDatumsAsInline = True
      }

  void $ waitUntilSlot 2

  callEndpoint @"close-live-address" h1 $
    CloseAddressParams
      { closeBeaconsBurned = [(adaToken,-1)]
      , closeBeaconSwapConfig = beaconSwapConfig
      , closeAddressSwapConfig = addressSwapConfig
      , closeAddress = swapAddress
      , closeAll = True
      , closeSpecificUtxos = []
      }

closeAddressAndWithdrawBeacon :: EmulatorTrace ()
closeAddressAndWithdrawBeacon = do
  h1 <- activateContractWallet (knownWallet 1) endpoints

  let beaconSwapConfig = swapConfig1
      addressSwapConfig = swapConfig1

      beaconSymbol' = beaconSymbol $ convert2SwapConfig beaconSwapConfig

      swapDatum' = SwapDatum'
        { swapPrice' = unsafeRatio 2 1
        , swapBeacon' = Just beaconSymbol'
        }

      swapAddress = Address 
        (ScriptCredential $ swapValidatorHash $ convert2SwapConfig addressSwapConfig)
        (Just $ StakingHash 
              $ PubKeyCredential 
              $ unPaymentPubKeyHash 
              $ mockWalletPaymentPubKeyHash 
              $ knownWallet 1)

  callEndpoint @"create-live-swap-address" h1 $
    CreateLiveSwapAddressParams
      { beaconsMinted = [(adaToken,1)]
      , useMintRedeemer = True
      , createLiveBeaconSwapConfig = beaconSwapConfig
      , createLiveAddressSwapConfig = addressSwapConfig
      , createLiveAddress = swapAddress
      , createLiveRefScript = Proper
      , createLiveRefScriptUtxo =
          ( Just swapDatum'
          , singleton beaconSymbol' adaToken 1 <> refScriptDeposit
          )
      , createLiveInitialPositions =
          [ ( Just swapDatum'
            , lovelaceValueOf 100_000_000
            )
          ]
      , createLiveDatumsAsInline = True
      }

  void $ waitUntilSlot 2

  callEndpoint @"close-live-address" h1 $
    CloseAddressParams
      { closeBeaconsBurned = []
      , closeBeaconSwapConfig = beaconSwapConfig
      , closeAddressSwapConfig = addressSwapConfig
      , closeAddress = swapAddress
      , closeAll = True
      , closeSpecificUtxos = []
      }

closeAddressButLeaveBeaconUtxo :: EmulatorTrace ()
closeAddressButLeaveBeaconUtxo = do
  h1 <- activateContractWallet (knownWallet 1) endpoints

  let beaconSwapConfig = swapConfig1
      addressSwapConfig = swapConfig1

      beaconSymbol' = beaconSymbol $ convert2SwapConfig beaconSwapConfig

      swapDatum' = SwapDatum'
        { swapPrice' = unsafeRatio 2 1
        , swapBeacon' = Just beaconSymbol'
        }

      swapAddress = Address 
        (ScriptCredential $ swapValidatorHash $ convert2SwapConfig addressSwapConfig)
        (Just $ StakingHash 
              $ PubKeyCredential 
              $ unPaymentPubKeyHash 
              $ mockWalletPaymentPubKeyHash 
              $ knownWallet 1)

  callEndpoint @"create-live-swap-address" h1 $
    CreateLiveSwapAddressParams
      { beaconsMinted = [(adaToken,1)]
      , useMintRedeemer = True
      , createLiveBeaconSwapConfig = beaconSwapConfig
      , createLiveAddressSwapConfig = addressSwapConfig
      , createLiveAddress = swapAddress
      , createLiveRefScript = Proper
      , createLiveRefScriptUtxo =
          ( Just swapDatum'
          , singleton beaconSymbol' adaToken 1 <> refScriptDeposit
          )
      , createLiveInitialPositions =
          [ ( Just swapDatum'
            , lovelaceValueOf 100_000_000
            )
          ]
      , createLiveDatumsAsInline = True
      }

  void $ waitUntilSlot 2

  callEndpoint @"close-live-address" h1 $
    CloseAddressParams
      { closeBeaconsBurned = []
      , closeBeaconSwapConfig = beaconSwapConfig
      , closeAddressSwapConfig = addressSwapConfig
      , closeAddress = swapAddress
      , closeAll = False
      , closeSpecificUtxos = [(swapDatum', lovelaceValueOf 100_000_000)]
      }

closeAddressAsNonOwner :: EmulatorTrace ()
closeAddressAsNonOwner = do
  h1 <- activateContractWallet (knownWallet 1) endpoints
  h2 <- activateContractWallet (knownWallet 2) endpoints

  let beaconSwapConfig = swapConfig1
      addressSwapConfig = swapConfig1

      beaconSymbol' = beaconSymbol $ convert2SwapConfig beaconSwapConfig

      swapDatum' = SwapDatum'
        { swapPrice' = unsafeRatio 2 1
        , swapBeacon' = Just beaconSymbol'
        }

      swapAddress = Address 
        (ScriptCredential $ swapValidatorHash $ convert2SwapConfig addressSwapConfig)
        (Just $ StakingHash 
              $ PubKeyCredential 
              $ unPaymentPubKeyHash 
              $ mockWalletPaymentPubKeyHash 
              $ knownWallet 1)

  callEndpoint @"create-live-swap-address" h1 $
    CreateLiveSwapAddressParams
      { beaconsMinted = [(adaToken,1)]
      , useMintRedeemer = True
      , createLiveBeaconSwapConfig = beaconSwapConfig
      , createLiveAddressSwapConfig = addressSwapConfig
      , createLiveAddress = swapAddress
      , createLiveRefScript = Proper
      , createLiveRefScriptUtxo =
          ( Just swapDatum'
          , singleton beaconSymbol' adaToken 1 <> refScriptDeposit
          )
      , createLiveInitialPositions =
          [ ( Just swapDatum'
            , lovelaceValueOf 100_000_000
            )
          ]
      , createLiveDatumsAsInline = True
      }

  void $ waitUntilSlot 2

  callEndpoint @"close-live-address" h2 $
    CloseAddressParams
      { closeBeaconsBurned = [(adaToken,-1)]
      , closeBeaconSwapConfig = beaconSwapConfig
      , closeAddressSwapConfig = addressSwapConfig
      , closeAddress = swapAddress
      , closeAll = True
      , closeSpecificUtxos = []
      }

closeAddressWithOtherBeaconsInInput :: EmulatorTrace ()
closeAddressWithOtherBeaconsInInput= do
  h1 <- activateContractWallet (knownWallet 1) endpoints

  let beaconSwapConfig = swapConfig1
      addressSwapConfig = swapConfig1

      beaconSymbol' = beaconSymbol $ convert2SwapConfig beaconSwapConfig

      swapDatum' = SwapDatum'
        { swapPrice' = unsafeRatio 2 1
        , swapBeacon' = Just beaconSymbol'
        }

      swapAddress = Address 
        (ScriptCredential $ swapValidatorHash $ convert2SwapConfig addressSwapConfig)
        (Just $ StakingHash 
              $ PubKeyCredential 
              $ unPaymentPubKeyHash 
              $ mockWalletPaymentPubKeyHash 
              $ knownWallet 1)

  callEndpoint @"create-live-swap-address" h1 $
    CreateLiveSwapAddressParams
      { beaconsMinted = [(adaToken,1)]
      , useMintRedeemer = True
      , createLiveBeaconSwapConfig = beaconSwapConfig
      , createLiveAddressSwapConfig = addressSwapConfig
      , createLiveAddress = swapAddress
      , createLiveRefScript = Proper
      , createLiveRefScriptUtxo =
          ( Just swapDatum'
          , singleton beaconSymbol' adaToken 1 <> refScriptDeposit
          )
      , createLiveInitialPositions =
          [ ( Just swapDatum'
            , lovelaceValueOf 100_000_000
            )
          ]
      , createLiveDatumsAsInline = True
      }

  void $ waitUntilSlot 2

  callEndpoint @"close-live-address" h1 $
    CloseAddressParams
      { closeBeaconsBurned = [(adaToken,-3)]
      , closeBeaconSwapConfig = beaconSwapConfig
      , closeAddressSwapConfig = addressSwapConfig
      , closeAddress = swapAddress
      , closeAll = True
      , closeSpecificUtxos = []
      }

-------------------------------------------------
-- Test Function
-------------------------------------------------
tests :: TestTree
tests = do
  let opts = defaultCheckOptions & emulatorConfig .~ emConfig
  testGroup "Closing Live Addresses"
    [ checkPredicateOptions opts "Successfully close all utxos and burn beacon"
        assertNoFailedTransactions closeAddressAndRemoveAllUtxos
    , checkPredicateOptions opts "Fail if swap's beacon among inputs but not burned"
        (Test.not assertNoFailedTransactions) closeAddressAndWithdrawBeacon
    , checkPredicateOptions opts "Successfully close non-beacon utxos without burning beacon"
        assertNoFailedTransactions closeAddressButLeaveBeaconUtxo
    , checkPredicateOptions opts "Fail if staking pubkey didn't sign"
        (Test.not assertNoFailedTransactions) closeAddressAsNonOwner
    , checkPredicateOptions opts "Fail if not all beacons in inputs burned"
        (Test.not assertNoFailedTransactions) closeAddressWithOtherBeaconsInInput
    ]

testTrace :: IO ()
testTrace = runEmulatorTraceIO' def emConfig closeAddressWithOtherBeaconsInInput