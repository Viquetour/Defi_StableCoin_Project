'use client';

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { Transaction } from '@/types/index';

export const useTransactionHistory = () => {
  const { address } = useAccount();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!address) {
      setTransactions([]);
      return;
    }

    // TODO: Fetch transaction history from subgraph or API
    setIsLoading(true);
    try {
      // Mock data - replace with actual API call
      setTransactions([]);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch transactions');
    } finally {
      setIsLoading(false);
    }
  }, [address]);

  return { transactions, isLoading, error };
};
