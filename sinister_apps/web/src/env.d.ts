declare module 'lucide-react' {
  import { FC, SVGProps } from 'react';
  export const Building2: FC<SVGProps<SVGSVGElement>>;
  export const Puzzle: FC<SVGProps<SVGSVGElement>>;
}

declare module '@npwd/sdk' {
  export function fetchNui<T = any>(event: string, data?: any): Promise<T>;
}

declare module '@npwd/keyos' {}
declare module 'motion/react' {}

interface Window {
  GetParentResourceName: () => string;
}
