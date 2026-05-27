'use client';

import React from 'react';
import { useAccount } from 'wagmi';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import Link from 'next/link';
import { getHealthFactorColor, getHealthFactorStatus } from '@/utils/format';

interface PortfolioItem {
  token: string;
  amount: number;
  usdValue: number;
  apy: number;
}

export const Dashboard: React.FC = () => {
  const { isConnected } = useAccount();

  // TODO: Fetch from contract
  const deposits: PortfolioItem[] = [];
  const borrows: PortfolioItem[] = [];
  const healthFactor = 0;
  const totalDeposits = 0;
  const totalBorrows = 0;
  const earned = 0;
  const netAPY = 0;

  const status = getHealthFactorStatus(healthFactor);
  const statusColors = {
    safe: 'bg-success-100 text-success-800',
    warning: 'bg-warning-100 text-warning-800',
    danger: 'bg-danger-100 text-danger-800',
  };

  if (!isConnected) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen">
        <Card className="w-full max-w-md">
          <div className="text-center space-y-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
              <p className="text-gray-600 mt-2">Connect your wallet to start</p>
            </div>
            <div className="flex flex-col gap-2">
              <Button fullWidth variant="primary">
                Connect Wallet
              </Button>
            </div>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Total Deposits</p>
            <p className="text-3xl font-bold text-gray-900">${totalDeposits.toLocaleString()}</p>
            <p className="text-xs text-gray-500">in your account</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Total Borrows</p>
            <p className="text-3xl font-bold text-danger-600">${totalBorrows.toLocaleString()}</p>
            <p className="text-xs text-gray-500">outstanding debt</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Earned</p>
            <p className="text-3xl font-bold text-success-600">${earned.toLocaleString()}</p>
            <p className="text-xs text-gray-500">total interest</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Net APY</p>
            <p className={`text-3xl font-bold ${netAPY >= 0 ? 'text-success-600' : 'text-danger-600'}`}>
              {netAPY.toFixed(2)}%
            </p>
            <p className="text-xs text-gray-500">weighted average</p>
          </div>
        </Card>
      </div>

      {/* Health Factor */}
      <Card>
        <div className="flex items-center justify-between">
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Account Health</p>
            <p className={`text-4xl font-bold ${getHealthFactorColor(healthFactor)}`}>
              {healthFactor.toFixed(2)}
            </p>
          </div>
          <div className="text-right space-y-2">
            <span className={`inline-block px-3 py-1 text-sm font-semibold rounded-lg ${statusColors[status]}`}>
              {status.charAt(0).toUpperCase() + status.slice(1)}
            </span>
            {status === 'danger' && (
              <p className="text-xs text-danger-600">
                Your account is at risk of liquidation
              </p>
            )}
          </div>
        </div>
      </Card>

      {/* Deposits */}
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-2xl font-bold text-gray-900">Deposits</h2>
          <Link href="/deposit">
            <Button variant="primary">+ Deposit</Button>
          </Link>
        </div>

        {deposits.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {deposits.map((item) => (
              <Card key={item.token}>
                <div className="flex justify-between items-start">
                  <div>
                    <p className="text-sm font-medium text-gray-600">{item.token}</p>
                    <p className="text-2xl font-bold text-gray-900">{item.amount}</p>
                    <p className="text-xs text-gray-500">${item.usdValue}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-success-600 font-semibold">{item.apy}% APY</p>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        ) : (
          <Card className="text-center py-8">
            <p className="text-gray-600">No deposits yet</p>
          </Card>
        )}
      </div>

      {/* Borrows */}
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-2xl font-bold text-gray-900">Borrows</h2>
          <Link href="/borrow">
            <Button variant="primary">+ Borrow</Button>
          </Link>
        </div>

        {borrows.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {borrows.map((item) => (
              <Card key={item.token}>
                <div className="flex justify-between items-start">
                  <div>
                    <p className="text-sm font-medium text-gray-600">{item.token}</p>
                    <p className="text-2xl font-bold text-gray-900">{item.amount}</p>
                    <p className="text-xs text-gray-500">${item.usdValue}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-danger-600 font-semibold">{item.apy}% APY</p>
                    <Link href="/repay">
                      <Button variant="ghost" size="sm" className="mt-2">
                        Repay
                      </Button>
                    </Link>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        ) : (
          <Card className="text-center py-8">
            <p className="text-gray-600">No active borrows</p>
          </Card>
        )}
      </div>
    </div>
  );
};
