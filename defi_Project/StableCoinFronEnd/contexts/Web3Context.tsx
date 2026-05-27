'use client';

import React, { createContext, useContext, ReactNode } from 'react';
import { useAccount } from 'wagmi';
import { DashboardStats, UserPosition } from '@/types/index';

interface Web3ContextType {
  isConnected: boolean;
  address: `0x${string}` | undefined;
  chainId: number | undefined;
  dashboardStats: DashboardStats | null;
  userPosition: UserPosition | null;
  isLoading: boolean;
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined);

export const Web3Provider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const { address, isConnected, chainId } = useAccount();

  // TODO: Fetch dashboard stats from contract
  const dashboardStats: DashboardStats = {
    totalDeposits: BigInt(0),
    totalBorrows: BigInt(0),
    netAPY: 0,
    healthFactor: 0,
    earned: BigInt(0),
    borrowed: BigInt(0),
  };

  // TODO: Fetch user position from contract
  const userPosition: UserPosition = {
    deposits: BigInt(0),
    borrows: BigInt(0),
    collateral: BigInt(0),
    healthFactor: 0,
  };

  const value: Web3ContextType = {
    isConnected,
    address,
    chainId,
    dashboardStats,
    userPosition,
    isLoading: false,
  };

  return <Web3Context.Provider value={value}>{children}</Web3Context.Provider>;
};

export const useWeb3 = (): Web3ContextType => {
  const context = useContext(Web3Context);
  if (context === undefined) {
    throw new Error('useWeb3 must be used within a Web3Provider');
  }
  return context;
};
