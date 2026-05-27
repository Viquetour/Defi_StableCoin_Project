import React from 'react';
import { Card, CardHeader, CardBody, CardFooter } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';

export const metadata = {
  title: 'Repay - DeFi Protocol',
  description: 'Repay your borrowed tokens',
};

export default function RepayPage() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-4xl font-bold text-gray-900">Repay Loans</h1>
        <p className="text-gray-600 mt-2">Repay your borrowed tokens</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Outstanding Debt</p>
            <p className="text-3xl font-bold text-gray-900">0.00 USDC</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Interest Owed</p>
            <p className="text-3xl font-bold text-danger-600">0.00 USDC</p>
          </div>
        </Card>

        <Card>
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-600">Total Payment</p>
            <p className="text-3xl font-bold text-gray-900">0.00 USDC</p>
          </div>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <h2 className="text-2xl font-bold text-gray-900">Repay Loan</h2>
        </CardHeader>

        <CardBody>
          <div className="space-y-4">
            <Input label="Repay Amount" type="number" placeholder="Enter amount" />

            <Button fullWidth variant="primary">
              Repay Loan
            </Button>
          </div>
        </CardBody>

        <CardFooter>
          <p className="text-sm text-gray-600">
            Current Interest Rate: <span className="font-semibold">3.5%</span>
          </p>
        </CardFooter>
      </Card>
    </div>
  );
}
