export const siteConfig = {
  name: 'DeFi Protocol Frontend',
  description: 'A modern and secure DeFi protocol frontend with deposit, borrow, and trading features',
  url: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
  ogImage: '/og.jpg',
  links: {
    twitter: 'https://twitter.com',
    github: 'https://github.com',
    docs: '/docs',
  },
};

export const navConfig = {
  mainNav: [
    {
      title: 'Dashboard',
      href: '/',
      description: 'View your portfolio and account summary',
    },
    {
      title: 'Deposit',
      href: '/deposit',
      description: 'Deposit tokens to earn interest',
    },
    {
      title: 'Borrow',
      href: '/borrow',
      description: 'Borrow tokens against your collateral',
    },
    {
      title: 'Repay',
      href: '/repay',
      description: 'Repay your borrowed tokens',
    },
    {
      title: 'Liquidations',
      href: '/liquidations',
      description: 'Find and liquidate undercollateralized positions',
    },
  ],
};

export const contractsConfig = {
  mainnet: {
    PROTOCOL_ADDRESS: process.env.NEXT_PUBLIC_PROTOCOL_ADDRESS || '',
    TOKEN_ADDRESS: process.env.NEXT_PUBLIC_TOKEN_ADDRESS || '',
    USDC_ADDRESS: process.env.NEXT_PUBLIC_USDC_ADDRESS || '',
  },
  sepolia: {
    PROTOCOL_ADDRESS: process.env.NEXT_PUBLIC_PROTOCOL_ADDRESS || '',
    TOKEN_ADDRESS: process.env.NEXT_PUBLIC_TOKEN_ADDRESS || '',
    USDC_ADDRESS: process.env.NEXT_PUBLIC_USDC_ADDRESS || '',
  },
};
