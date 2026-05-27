import {
  getDefaultConfig,
} from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';

// @ts-ignore - RainbowKit type inference (acceptable for config object)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const config: any = getDefaultConfig({
  appName: 'DeFi Protocol Frontend',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || '',
  chains: [sepolia],
  ssr: true,
});

export const supportedChains = [
  {
    id: sepolia.id,
    name: 'Sepolia Testnet',
    rpcUrl: process.env.NEXT_PUBLIC_RPC_SEPOLIA || '',
  },
];
