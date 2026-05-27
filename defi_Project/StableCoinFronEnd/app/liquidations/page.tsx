import { LiquidationsView } from '@/components/Liquidations';

export const metadata = {
  title: 'Liquidations - DeFi Protocol',
  description: 'Liquidate undercollateralized positions',
};

export default function LiquidationsPage() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-4xl font-bold text-gray-900">Liquidations</h1>
        <p className="text-gray-600 mt-2">Find and liquidate undercollateralized positions</p>
      </div>
      <LiquidationsView />
    </div>
  );
}
