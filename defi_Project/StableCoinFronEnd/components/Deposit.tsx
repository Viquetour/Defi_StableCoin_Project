'use client';

import React, { useState } from 'react';
import { useAccount } from 'wagmi';
import { Card, CardHeader, CardBody, CardFooter } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { useDeposit } from '@/hooks/useContractInteractions';

interface DepositFormProps {
  tokenAddress?: `0x${string}`;
  onSuccess?: () => void;
}

export const DepositForm: React.FC<DepositFormProps> = ({
  tokenAddress = '0x0000000000000000000000000000000000000000',
  onSuccess,
}) => {
  const { isConnected } = useAccount();
  const { deposit, isPending } = useDeposit();
  const [amount, setAmount] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!isConnected) {
      setError('Please connect your wallet');
      return;
    }

    if (!amount || parseFloat(amount) <= 0) {
      setError('Please enter a valid amount');
      return;
    }

    try {
      const parsedAmount = BigInt(parseFloat(amount) * 10 ** 18);
      await deposit(tokenAddress, parsedAmount);
      setAmount('');
      onSuccess?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to deposit');
    }
  };

  return (
    <Card>
      <CardHeader>
        <h2 className="text-2xl font-bold text-gray-900">Deposit</h2>
        <p className="text-gray-600 mt-1">Deposit tokens to earn interest</p>
      </CardHeader>

      <CardBody>
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Amount"
            type="number"
            placeholder="Enter deposit amount"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            disabled={!isConnected || isPending}
            helperText="Enter the amount you want to deposit"
          />

          {error && <div className="p-3 bg-danger-50 border border-danger-200 rounded-lg text-danger-700">{error}</div>}

          <Button
            type="submit"
            fullWidth
            isLoading={isPending}
            disabled={!isConnected || !amount}
          >
            {isConnected ? 'Deposit' : 'Connect Wallet'}
          </Button>
        </form>
      </CardBody>

      <CardFooter>
        <div className="text-sm text-gray-600">
          <p>Deposit APY: <span className="font-semibold text-success-600">5.5%</span></p>
        </div>
      </CardFooter>
    </Card>
  );
};

export const DepositView: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Available Balance</p>
            <p className="text-3xl font-bold text-gray-900">0.00 USDC</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Total Deposited</p>
            <p className="text-3xl font-bold text-gray-900">0.00 USDC</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Earned</p>
            <p className="text-3xl font-bold text-success-600">0.00 USDC</p>
          </div>
        </Card>
      </div>

      <DepositForm />
    </div>
  );
};
