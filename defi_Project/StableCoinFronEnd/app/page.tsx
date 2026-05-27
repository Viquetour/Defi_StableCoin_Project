import { Dashboard } from '@/components/Dashboard';

export const metadata = {
  title: 'Dashboard - DeFi Protocol',
  description: 'View your DeFi portfolio and account summary',
};

export default function Home() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-4xl font-bold text-gray-900">Your Portfolio</h1>
        <p className="text-gray-600 mt-2">Manage your deposits, borrows, and positions</p>
      </div>
      <Dashboard />
    </div>
  );
}
