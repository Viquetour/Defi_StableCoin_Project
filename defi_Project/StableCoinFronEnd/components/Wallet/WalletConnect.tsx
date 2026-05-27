'use client';

import React from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';

export const WalletConnect: React.FC = () => {
  return (
    <div className="flex justify-end">
      <ConnectButton
        accountStatus="avatar"
        showBalance={{
          smallScreen: false,
          largeScreen: true,
        }}
      />
    </div>
  );
};

export const WalletStatus: React.FC = () => {
  return (
    <div className="w-full max-w-sm mx-auto py-8">
      <ConnectButton showBalance />
    </div>
  );
};
