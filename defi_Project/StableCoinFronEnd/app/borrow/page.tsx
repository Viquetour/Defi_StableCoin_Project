import { BorrowView } from '@/components/Borrow';

export const metadata = {
  title: 'Borrow - DeFi Protocol',
  description: 'Borrow tokens against your collateral',
};

export default function BorrowPage() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-4xl font-bold text-gray-900">Borrow Tokens</h1>
        <p className="text-gray-600 mt-2">Borrow against your collateral</p>
      </div>
      <BorrowView />
    </div>
  );
}
