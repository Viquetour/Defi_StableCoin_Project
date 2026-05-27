'use client';

import React, { useState } from 'react';
import { useAccount } from 'wagmi';
import { Card, CardHeader, CardBody, CardFooter } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { useBorrow } from '@/hooks/useContractInteractions';
import { getHealthFactorColor, getHealthFactorStatus } from '@/utils/format';

interface BorrowFormProps {
  tokenAddress?: `0x${string}`;
  onSuccess?: () => void;
}

export const BorrowForm: React.FC<BorrowFormProps> = ({
  tokenAddress = '0x0000000000000000000000000000000000000000',
  onSuccess,
}) => {
  const { isConnected } = useAccount();
  const { borrow, isPending } = useBorrow();
  const [amount, setAmount] = useState('');
  const [error, setError] = useState('');

  const healthFactor = 2.5; // TODO: Get from contract
  const maxBorrowAmount = 1000; // TODO: Calculate from collateral

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

    if (parseFloat(amount) > maxBorrowAmount) {
      setError(`Maximum borrowable amount is ${maxBorrowAmount}`);
      return;
    }

    try {
      const parsedAmount = BigInt(parseFloat(amount) * 10 ** 18);
      await borrow(tokenAddress, parsedAmount);
      setAmount('');
      onSuccess?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to borrow');
    }
  };

  return (
    <Card>
      <CardHeader>
        <h2 className="text-2xl font-bold text-gray-900">Borrow</h2>
        <p className="text-gray-600 mt-1">Borrow against your collateral</p>
      </CardHeader>

      <CardBody>
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Amount"
            type="number"
            placeholder="Enter borrow amount"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            disabled={!isConnected || isPending}
            helperText={`Max: ${maxBorrowAmount} USDC`}
          />

          {error && <div className="p-3 bg-danger-50 border border-danger-200 rounded-lg text-danger-700">{error}</div>}

          <Button
            type="submit"
            fullWidth
            isLoading={isPending}
            disabled={!isConnected || !amount}
          >
            {isConnected ? 'Borrow' : 'Connect Wallet'}
          </Button>
        </form>
      </CardBody>

      <CardFooter>
        <div className="space-y-2">
          <p className="text-sm text-gray-600">
            Borrow APY: <span className="font-semibold text-danger-600">3.5%</span>
          </p>
          <p className={`text-sm font-semibold ${getHealthFactorColor(healthFactor)}`}>
            Health Factor: {healthFactor.toFixed(2)}
          </p>
        </div>
      </CardFooter>
    </Card>
  );
};

export const BorrowView: React.FC = () => {
  const healthFactor = 2.5; // TODO: Get from contract
  const status = getHealthFactorStatus(healthFactor);

  const statusColors = {
    safe: 'bg-success-100 text-success-800',
    warning: 'bg-warning-100 text-warning-800',
    danger: 'bg-danger-100 text-danger-800',
  };

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Collateral Value</p>
            <p className="text-3xl font-bold text-gray-900">0.00 USDC</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Total Borrowed</p>
            <p className="text-3xl font-bold text-gray-900">0.00 USDC</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Health Factor</p>
            <p className={`text-3xl font-bold ${getHealthFactorColor(healthFactor)}`}>
              {healthFactor.toFixed(2)}
            </p>
            <span className={`inline-block px-2 py-1 text-xs font-semibold rounded ${statusColors[status]}`}>
              {status}
            </span>
          </div>
        </Card>
      </div>

      <BorrowForm />
    </div>
  );
};
