export const formatAddress = (address: string | undefined): string => {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

export const formatNumber = (num: number, decimals: number = 2): string => {
  return num.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: decimals,
  });
};

export const formatCurrency = (amount: bigint, decimals: number = 18): string => {
  const divisor = BigInt(10) ** BigInt(decimals);
  const whole = amount / divisor;
  const fraction = amount % divisor;

  const fractionStr = fraction
    .toString()
    .padStart(decimals, '0')
    .substring(0, 2);

  return `${whole}.${fractionStr}`;
};

export const parseAmount = (amount: string, decimals: number = 18): bigint => {
  const [whole, fraction] = amount.split('.');
  const paddedFraction = (fraction || '0').padEnd(decimals, '0').substring(0, decimals);
  return BigInt(whole) * BigInt(10) ** BigInt(decimals) + BigInt(paddedFraction);
};

export const formatPercentage = (value: number, decimals: number = 2): string => {
  return `${(value * 100).toFixed(decimals)}%`;
};

export const getHealthFactorColor = (healthFactor: number): string => {
  if (healthFactor < 1.1) return 'text-danger-500';
  if (healthFactor < 1.5) return 'text-warning-500';
  return 'text-success-500';
};

export const getHealthFactorStatus = (
  healthFactor: number
): 'danger' | 'warning' | 'safe' => {
  if (healthFactor < 1.1) return 'danger';
  if (healthFactor < 1.5) return 'warning';
  return 'safe';
};

export const truncateString = (str: string, length: number = 50): string => {
  if (str.length <= length) return str;
  return `${str.slice(0, length)}...`;
};
