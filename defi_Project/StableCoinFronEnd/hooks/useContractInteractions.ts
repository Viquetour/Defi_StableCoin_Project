'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAccount, useWriteContract } from 'wagmi';
import { PoolInfo } from '@/types/index';

export const usePoolData = () => {
  const [pools] = useState<PoolInfo[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error] = useState<string | null>(null);

  useEffect(() => {
    // TODO: Fetch pool data from contract
    setIsLoading(false);
  }, []);

  return { pools, isLoading, error };
};

export const useDeposit = () => {
  const { address } = useAccount();
  const { writeContract, isPending } = useWriteContract();

  const deposit = useCallback(
    async (tokenAddress: `0x${string}`, amount: bigint) => {
      if (!address) throw new Error('Wallet not connected');

      writeContract({
        address: process.env.NEXT_PUBLIC_PROTOCOL_ADDRESS as `0x${string}`,
        functionName: 'deposit',
        args: [tokenAddress, amount],
        abi: [
          {
            name: 'deposit',
            type: 'function',
            inputs: [
              { name: 'token', type: 'address' },
              { name: 'amount', type: 'uint256' },
            ],
            outputs: [],
          },
        ],
      });
    },
    [address, writeContract]
  );

  return { deposit, isPending };
};

export const useBorrow = () => {
  const { address } = useAccount();
  const { writeContract, isPending } = useWriteContract();

  const borrow = useCallback(
    async (tokenAddress: `0x${string}`, amount: bigint) => {
      if (!address) throw new Error('Wallet not connected');

      writeContract({
        address: process.env.NEXT_PUBLIC_PROTOCOL_ADDRESS as `0x${string}`,
        functionName: 'borrow',
        args: [tokenAddress, amount],
        abi: [
          {
            name: 'borrow',
            type: 'function',
            inputs: [
              { name: 'token', type: 'address' },
              { name: 'amount', type: 'uint256' },
            ],
            outputs: [],
          },
        ],
      });
    },
    [address, writeContract]
  );

  return { borrow, isPending };
};

export const useWithdraw = () => {
  const { address } = useAccount();
  const { writeContract, isPending } = useWriteContract();

  const withdraw = useCallback(
    async (tokenAddress: `0x${string}`, amount: bigint) => {
      if (!address) throw new Error('Wallet not connected');

      writeContract({
        address: process.env.NEXT_PUBLIC_PROTOCOL_ADDRESS as `0x${string}`,
        functionName: 'withdraw',
        args: [tokenAddress, amount],
        abi: [
          {
            name: 'withdraw',
            type: 'function',
            inputs: [
              { name: 'token', type: 'address' },
              { name: 'amount', type: 'uint256' },
            ],
            outputs: [],
          },
        ],
      });
    },
    [address, writeContract]
  );

  return { withdraw, isPending };
};

export const useRepay = () => {
  const { address } = useAccount();
  const { writeContract, isPending } = useWriteContract();

  const repay = useCallback(
    async (tokenAddress: `0x${string}`, amount: bigint) => {
      if (!address) throw new Error('Wallet not connected');

      writeContract({
        address: process.env.NEXT_PUBLIC_PROTOCOL_ADDRESS as `0x${string}`,
        functionName: 'repay',
        args: [tokenAddress, amount],
        abi: [
          {
            name: 'repay',
            type: 'function',
            inputs: [
              { name: 'token', type: 'address' },
              { name: 'amount', type: 'uint256' },
            ],
            outputs: [],
          },
        ],
      });
    },
    [address, writeContract]
  );

  return { repay, isPending };
};
