'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import clsx from 'clsx';
import { WalletConnect } from './Wallet/WalletConnect';

const navigation = [
  { name: 'Dashboard', href: '/' },
  { name: 'Deposit', href: '/deposit' },
  { name: 'Borrow', href: '/borrow' },
  { name: 'Repay', href: '/repay' },
  { name: 'Liquidations', href: '/liquidations' },
];

export const Header: React.FC = () => {
  const pathname = usePathname();

  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-br from-primary-600 to-primary-700 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-lg">D</span>
            </div>
            <span className="font-bold text-xl text-gray-900 hidden sm:inline">
              DeFi Protocol
            </span>
          </Link>

          {/* Navigation Links */}
          <div className="hidden md:flex items-center space-x-1">
            {navigation.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                className={clsx(
                  'px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200',
                  pathname === item.href
                    ? 'bg-primary-100 text-primary-700'
                    : 'text-gray-600 hover:bg-gray-100'
                )}
              >
                {item.name}
              </Link>
            ))}
          </div>

          {/* Wallet Connect */}
          <div>
            <WalletConnect />
          </div>
        </div>
      </nav>
    </header>
  );
};
