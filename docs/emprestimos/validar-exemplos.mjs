// Evidencia documental; nao importa servicos nem acessa banco, rede ou dados reais.
// Executar da raiz: node docs/emprestimos/validar-exemplos.mjs
import assert from 'node:assert/strict';

// Razoes de inteiros positivos, arredondadas ao centavo por HALF_UP.
const roundRatio = (a, b) => (2n * a + b) / (2n * b);
const money = value => `${value < 0n ? '-' : ''}${(value < 0n ? -value : value) / 100n}.${String((value < 0n ? -value : value) % 100n).padStart(2, '0')}`;
const price = (principalCents, rateNumerator, rateDenominator, count) => {
  if (rateNumerator === 0n) return roundRatio(principalCents, BigInt(count));
  const growth = (rateDenominator + rateNumerator) ** BigInt(count);
  return roundRatio(principalCents * rateNumerator * growth,
    rateDenominator * (growth - rateDenominator ** BigInt(count)));
};
const schedule = (principal, numerator, denominator, count) => {
  const installment = price(principal, numerator, denominator, count);
  let balance = principal;
  const rows = [];
  for (let sequence = 1; sequence <= count; sequence++) {
    const interest = roundRatio(balance * numerator, denominator);
    const amortization = installment - interest;
    balance -= amortization;
    rows.push({ sequence, installment: money(installment), interest: money(interest), principal: money(amortization), balance: money(balance) });
  }
  return { installment, balance, rows };
};

const single = roundRatio(70000n * 120n, 100n);
const reference = schedule(100000n, 139n, 1000n, 3);
const fine = roundRatio(43001n * 2n, 100n);
const arrears = roundRatio(43001n * 21n, 100n * 30n);
const residual = schedule(100000n, 1n, 100n, 3);
const zero = price(10000n, 0n, 100n, 3);
assert.equal(single, 84000n);
assert.equal(reference.installment, 43001n);
assert.equal(reference.installment * 3n, 129003n);
assert.equal(reference.balance, 0n);
assert.equal(fine, 860n);
assert.equal(arrears, 301n);
assert.equal(43001n + fine + arrears, 44162n);
assert.equal(residual.installment, 34002n);
assert.equal(residual.balance, 1n);
assert.equal(zero * 3n, 9999n);
console.log(JSON.stringify({
  single: money(single),
  priceReference: reference.rows,
  latePayment: { fine: money(fine), arrears: money(arrears), total: money(43001n + fine + arrears) },
  priceResidual: residual.rows,
  zeroRate: { principal: '100.00', installment: money(zero), total: money(zero * 3n), difference: money(10000n - zero * 3n) },
  result: '10 assertions passed; documentary examples only'
}, null, 2));
