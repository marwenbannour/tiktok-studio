"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { href: "/", label: "الإحصائيات" },
  { href: "/models", label: "الموديلات" },
  { href: "/generate", label: "المولّد" },
];

export default function Nav() {
  const path = usePathname();
  return (
    <nav className="nav">
      {links.map((l) => (
        <Link key={l.href} href={l.href} className={path === l.href ? "active" : ""}>
          {l.label}
        </Link>
      ))}
    </nav>
  );
}
