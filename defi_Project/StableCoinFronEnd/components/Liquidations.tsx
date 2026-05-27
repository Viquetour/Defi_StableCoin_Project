'use client';

import React, { useState } from 'react';
import { useAccount } from 'wagmi';
import { Card, CardHeader, CardBody } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';

interface LiquidationOpportunity {
  id: string;
  user: string;
  collateral: string;
  debt: number;
  healthFactor: number;
  liquidationBonus: number;
}

export const LiquidationsView: React.FC = () => {
  const { isConnected } = useAccount();
  const [targetUser, setTargetUser] = useState('');

  const liquidationOpportunities: LiquidationOpportunity[] = [
    {
      id: '1',
      user: '0x1234...5678',
      collateral: 'ETH',
      debt: 50000,
      healthFactor: 0.95,
      liquidationBonus: 5,
    },
    {
      id: '2',
      user: '0x8765...4321',
      collateral: 'USDC',
      debt: 100000,
      healthFactor: 1.05,
      liquidationBonus: 5,
    },
  ];

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <h2 className="text-2xl font-bold text-gray-900">Liquidations</h2>
          <p className="text-gray-600 mt-1">Liquidate undercollateralized positions</p>
        </CardHeader>

        <CardBody>
          <div className="space-y-4">
            <Input
              label="User Address"
              type="text"
              placeholder="0x..."
              value={targetUser}
              onChange={(e) => setTargetUser(e.target.value)}
              disabled={!isConnected}
              helperText="Enter the address of the user to liquidate"
            />

            <Button disabled={!isConnected} fullWidth>
              {isConnected ? 'Search Position' : 'Connect Wallet'}
            </Button>
          </div>
        </CardBody>
      </Card>

      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Available Opportunities</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {liquidationOpportunities.map((opp) => (
            <Card key={opp.id}>
              <div className="space-y-3">
                <div className="flex justify-between items-start">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Account</p>
                    <p className="text-lg font-semibold text-gray-900">{opp.user}</p>
                  </div>
                  <span className="px-3 py-1 bg-danger-100 text-danger-800 text-xs font-semibold rounded-full">
                    {opp.healthFactor.toFixed(2)}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-gray-500 uppercase font-semibold">Collateral</p>
                    <p className="text-lg font-semibold text-gray-900">{opp.collateral}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500 uppercase font-semibold">Debt</p>
                    <p className="text-lg font-semibold text-gray-900">${opp.debt.toLocaleString()}</p>
                  </div>
                </div>

                <div className="pt-2 border-t border-gray-200">
                  <p className="text-sm text-success-600 font-semibold">
                    Bonus: {opp.liquidationBonus}%
                  </p>
                </div>

                <Button
                  fullWidth
                  variant="danger"
                  disabled={!isConnected}
                >
                  Liquidate
                </Button>
              </div>
            </Card>
          ))}
        </div>

        {liquidationOpportunities.length === 0 && (
          <Card>
            <div className="text-center py-8">
              <p className="text-gray-600">No liquidation opportunities available</p>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
};
