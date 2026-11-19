// Exemplos sintéticos de especificação; não é motor de produção nem usa banco.
import assert from 'node:assert/strict';

const round = (n, d) => (2n * n + d) / (2n * d); // valores não negativos
const min = (a, b) => a < b ? a : b;
const order = ['multa', 'juros', 'mora', 'avulso', 'principal'];
function allocate(input, amount) {
  const balances = { ...input }, paid = {};
  const total = order.reduce((s, k) => s + balances[k], 0n);
  if (amount <= 0n || amount > total) throw new Error('valor fora do saldo');
  for (const k of order) {
    paid[k] = min(balances[k], amount);
    balances[k] -= paid[k]; amount -= paid[k];
  }
  return { balances, paid };
}
const state = (principal, juros = 0n, multa = 0n, mora = 0n, avulso = 0n) => ({ principal, juros, multa, mora, avulso });
let checks = 0;
function check(name, fn) { fn(); checks++; console.log(`OK ${name}`); }

check('prioridade de componentes e saldo', () => {
  const r = allocate(state(70000n,14000n,2000n,2000n,2000n), 19000n);
  assert.deepEqual(r.paid, state(0n,14000n,2000n,2000n,1000n));
  assert.deepEqual(r.balances, state(70000n,0n,0n,0n,1000n));
});
check('prorrogação exige quitação de juros antigos', () => {
  const r = allocate(state(70000n,14000n,2000n), 14000n);
  assert.equal(r.balances.juros, 2000n);
  assert.equal(r.paid.principal, 0n);
  const next = allocate(r.balances, 2000n);
  assert.equal(next.balances.juros, 0n);
  assert.equal(next.balances.principal + round(next.balances.principal * 20n,100n), 84000n);
});
check('rejeita pagamento acima da dívida sem mutação', () => {
  const s = state(10000n, 1000n); assert.throws(() => allocate(s,11001n));
  assert.deepEqual(s, state(10000n,1000n));
});
check('parcelas selecionada e depois mais antiga', () => {
  const balances = [10000n,10000n,10000n]; let payment = 15000n;
  for (const i of [2,0,1]) { const v = min(balances[i],payment); balances[i]-=v; payment-=v; }
  assert.deepEqual(balances,[5000n,10000n,0n]); assert.equal(payment,0n);
});
check('mora dias reais, meses 28 e 31', () => {
  assert.equal(round(43001n * 21n, 100n * 28n),323n);
  assert.equal(round(43001n * 21n, 100n * 31n),291n);
});
check('mora em meses diferentes sem arredondar cada trecho', () => {
  // R$ 1.000; taxa 1% ao mês; um dia em fevereiro de 28 e um em março de 31.
  const n = 100000n * (31n + 28n), d = 100n * 28n * 31n;
  assert.equal(round(n,d),68n);
});
check('dia do pagamento: escolha de quatro ou cinco dias', () => {
  assert.equal(round(100000n * 4n,100n * 30n),133n);
  assert.equal(round(100000n * 5n,100n * 30n),167n);
});
check('trinta dias: escolhas de base após pagamento parcial', () => {
  assert.equal(round(60000n,100n),600n);
  assert.equal(round(100000n * 15n + 60000n * 15n,100n * 30n),800n);
});
check('blocos completos aos 30 e 60 dias', () => {
  const blocks = days => Math.floor(days / 30);
  assert.deepEqual([29,30,31,59,60].map(blocks),[0,1,1,1,2]);
});
check('contraprova histórica: multa do dia abatida no mesmo pagamento é ambígua', () => {
  // Recebimento de R$ 400; multa paga primeiro; principal inicial R$ 1.000.
  // Dois pares de centavos satisfazem simultaneamente multa=2% do saldo após
  // pagamento e prioridade da multa, com arredondamento HALF_UP.
  for (const fine of [1224n,1225n]) {
    const r = allocate(state(100000n,0n,fine),40000n);
    assert.equal(round(r.balances.principal * 2n,100n),fine);
    assert.equal(r.paid.multa,fine);
    assert.equal(r.paid.multa+r.paid.principal,40000n);
  }
  assert.notEqual(1224n,1225n);
});
check('decisão: pagamento primeiro e multa nova depois', () => {
  const received = allocate(state(100000n),40000n);
  const newFine = round(received.balances.principal * 2n,100n);
  assert.equal(received.paid.principal,40000n);
  assert.equal(received.balances.principal,60000n);
  assert.equal(newFine,1200n);
  assert.equal(received.balances.principal + newFine,61200n);
  const priorFine = allocate(state(100000n,0n,2000n),40000n);
  assert.equal(priorFine.paid.multa,2000n);
  assert.equal(priorFine.paid.principal,38000n);
  assert.equal(priorFine.balances.principal,62000n);
  assert.equal(round(priorFine.balances.principal*2n,100n),1240n);
});
check('contraprova histórica: recebimento e redução de principal são conceitos distintos', () => {
  const fine = round((100000n-40000n)*2n,100n);
  assert.equal(fine,1200n);
  // Para amortizar R$ 400 depois de pagar multa de R$ 12, recebe-se R$ 412.
  const r = allocate(state(100000n,0n,fine),41200n);
  assert.equal(r.balances.principal,60000n);
});
check('cancelamento compensa principal já recebido', () => {
  const loan = 100000n, principalPaid = 20000n;
  assert.equal(loan-principalPaid,80000n);
  const interestReceived=10000n, interestRefund=4000n;
  assert.equal(interestReceived-interestRefund,6000n);
  assert.equal(principalPaid+80000n,loan);
});
check('histórico com desconto separa dinheiro de abatimento', () => {
  const original=50000n, discount=5000n, received=45000n;
  assert.equal(original-discount-received,0n);
  assert.notEqual(discount+received,received);
});
check('histórico com componente desconhecido não confirma', () => {
  const mayConfirm = payments => payments.every(p => p.date && p.components.every(x => x.known));
  const payment = { date:'2026-03-10', estimated:true, components:[{known:true},{known:false}] };
  assert.equal(mayConfirm([payment]),false);
  payment.components[1].known=true;
  assert.equal(mayConfirm([payment]),true);
  payment.date=null; assert.equal(mayConfirm([payment]),false);
});
check('perda recuperada preserva saldo e ordem', () => {
  const frozen=state(70000n,14000n,2000n), received=14000n;
  const r=allocate(frozen,received);
  assert.equal(r.balances.juros,2000n);
  assert.equal(r.balances.principal,70000n);
  assert.equal(Object.values(r.balances).reduce((a,b)=>a+b,0n),72000n);
});
check('correção de recebimento não inventa transferência', () => {
  const original = { amount:15000n, principal:15000n };
  const correction = { amountDelta:-5000n, principalDelta:-5000n, actualTransfer:0n };
  const correctedReceived=original.amount+correction.amountDelta;
  const correctedPrincipal=original.principal+correction.principalDelta;
  const currentBalance=85000n, revisedBalance=currentBalance-correction.principalDelta;
  assert.equal(correctedReceived,10000n); assert.equal(correctedPrincipal,10000n);
  assert.equal(revisedBalance,90000n); assert.equal(correction.actualTransfer,0n);
  assert.equal(original.amount,15000n); // registro original permanece íntegro
});
check('price: residual no último vencimento', () => {
  let balance=100000n;
  const installments=[];
  for(let i=0;i<3;i++) {
    const interest=round(balance,100n);
    const value=i===2 ? balance+interest : 34002n;
    const principal=value-interest;
    assert.ok(principal>=0n && principal<=balance);
    balance-=principal; installments.push(value);
  }
  assert.deepEqual(installments,[34002n,34002n,34003n]); assert.equal(balance,0n);
});
check('taxa zero: última parcela absorve diferença', () => {
  const p=10000n, regular=round(p,3n);
  assert.deepEqual([regular,regular,p-regular*2n],[3333n,3333n,3334n]);
});
console.log(`${checks} cenários documentais passaram; nenhum serviço foi homologado.`);
