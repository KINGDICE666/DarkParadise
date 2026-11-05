import { useBackend } from '../../backend';

type CreditPriceProps = {
  value: number;
  freeLabel?: string;
};

export const CreditPrice = ({ value, freeLabel }: CreditPriceProps) => {
  const { config } = useBackend();
  return (
    <>
      {config.credit_price_override ??
        (value === 0 && freeLabel ? freeLabel : value)}
    </>
  );
};
