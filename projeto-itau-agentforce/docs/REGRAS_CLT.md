# Regras CLT Implementadas

Base legal: CLT arts. 129-153 + Lei 13.467/2017 (Reforma Trabalhista).

## 1. Período aquisitivo e concessivo

- **Aquisitivo**: 12 meses em que você "ganha" o direito às férias
- **Concessivo**: empresa tem 12 meses após o aquisitivo para conceder
- Se ultrapassar concessivo → pagamento em dobro (art. 137)

**Campos**: `Periodo_Aquisitivo_Inicio__c`, `Periodo_Aquisitivo_Fim__c`, `Periodo_Concessivo_Fim__c`.

## 2. Dias de direito — escala do art. 130

Faltas injustificadas no aquisitivo reduzem os dias:

| Faltas injustificadas | Dias de direito |
|---|---|
| 0 a 5 | 30 |
| 6 a 14 | 24 |
| 15 a 23 | 18 |
| 24 a 32 | 12 |
| 33 ou mais | 0 (perde direito) |

**Formula `Dias_Direito__c`** (com switch CLT/PJ):
```
IF(
  ISPICKVAL(Regime_Contratacao__c, "PJ"),
  20,
  CASE(TRUE,
    Faltas_Injustificadas__c <= 5,  30,
    Faltas_Injustificadas__c <= 14, 24,
    Faltas_Injustificadas__c <= 23, 18,
    Faltas_Injustificadas__c <= 32, 12,
    0
  )
)
```

## 3. Fracionamento (art. 134, §1º)

- Máximo 3 períodos
- 1 período obrigatoriamente ≥ 14 dias corridos
- Demais períodos ≥ 5 dias corridos cada
- Não iniciar 2 dias antes de feriado ou DSR (art. 134, §3º)

## 4. Abono pecuniário (art. 143)

- Conversão de até **1/3** em dinheiro (máximo 10 dias quando direito = 30)
- Solicitação até 15 dias antes do fim do aquisitivo
- Valor = salário proporcional + 1/3 constitucional

**Validation Rule em `Saldo_Ferias__c`**:
```
OR(
  ISPICKVAL(Regime_Contratacao__c, "PJ") && Dias_Abono_Vendidos__c > 0,
  Dias_Abono_Vendidos__c > FLOOR(Dias_Direito__c / 3)
)
```

## 5. Aviso prévio ao colaborador (art. 135)

- Mínimo 30 dias de antecedência

## 6. Pagamento (art. 145)

- Até 2 dias antes do início
- Inclui adicional constitucional de 1/3

Não implementado no MVP da demo (folha fica fora do escopo).

## 7. PJ (regime contratual simulado Itaú)

- 20 dias úteis/ano
- Sem adicional de 1/3
- Sem abono pecuniário
- Aviso mínimo: 15 dias

## Matriz de validações no Screen Flow

| # | Regra | Bloqueio | Mensagem ao colaborador |
|---|---|---|---|
| V1 | Aviso de 30 dias | hard | "Férias devem ser solicitadas com no mínimo 30 dias de antecedência." |
| V2 | Saldo suficiente | hard | "Seu saldo disponível é de {!Dias_Disponiveis__c} dias." |
| V3 | Mínimo 5 dias | hard | "Cada período de férias precisa ter ao menos 5 dias corridos." |
| V4 | Dentro do concessivo | hard | "Você precisa gozar estas férias até {!Periodo_Concessivo_Fim__c}." |
| V5 | Não sexta/sábado/domingo | hard | "Férias não podem começar em sexta-feira ou fim de semana." |
| V6 | Não véspera de feriado | hard | "Férias não podem começar 2 dias antes de feriado." |
| V7 | Período ≥ 14 quando fracionar | hard | "Pelo menos um dos períodos precisa ter 14 dias ou mais." |
| V8 | Abono ≤ 1/3 | hard | "Você pode vender no máximo {!limite_abono} dias." |
