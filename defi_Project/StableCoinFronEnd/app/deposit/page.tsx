import { DepositView } from '@/components/Deposit';

export const metadata = {
  title: 'Deposit - DeFi Protocol',
  description: 'Deposit tokens to earn interest',
};

export default function DepositPage() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-4xl font-bold text-gray-900">Deposit Tokens</h1>
        <p className="text-gray-600 mt-2">Earn interest on your deposits</p>
      </div>
      <DepositView />
    </div>
  );
}
