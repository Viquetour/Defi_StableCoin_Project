export interface Token {
  address: `0x${string}`;
  symbol: string;
  decimals: number;
  name: string;
  logo?: string;
}

export interface PoolInfo {
  id: string;
  name: string;
  totalDeposits: bigint;
  totalBorrows: bigint;
  depositAPY: number;
  borrowAPY: number;
  utilizationRate: number;
}

export interface UserPosition {
  deposits: bigint;
  borrows: bigint;
  collateral: bigint;
  healthFactor: number;
}

export interface Transaction {
  hash: `0x${string}`;
  status: 'pending' | 'success' | 'failed';
  timestamp: number;
  type: 'deposit' | 'withdraw' | 'borrow' | 'repay' | 'liquidate';
  amount: bigint;
  token: Token;
}

export interface DashboardStats {
  totalDeposits: bigint;
  totalBorrows: bigint;
  netAPY: number;
  healthFactor: number;
  earned: bigint;
  borrowed: bigint;
}
