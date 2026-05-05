import { LightningElement, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import getSaldoCardData from '@salesforce/apex/SaldoFeriasController.getSaldoCardData';

export default class SaldoFeriasCard extends NavigationMixin(LightningElement) {
    userId = USER_ID;
    saldo;
    solicitacoes = [];
    loading = true;
    error;

    @wire(getSaldoCardData)
    wiredSaldo({ error, data }) {
        this.loading = false;
        if (data) {
            this.saldo = data.saldo;
            this.solicitacoes = (data.solicitacoes || []).map((solicitacao) => ({
                ...solicitacao,
                statusLabel: this.getStatusLabel(solicitacao),
                statusClass: this.getStatusClass(solicitacao),
                isAprovada: solicitacao.Aprovacao_Gestor__c === 'Aprovado'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.saldo = undefined;
            this.solicitacoes = [];
        }
    }

    get hasSaldo() {
        return !!this.saldo;
    }

    get noSaldo() {
        return !this.loading && !this.saldo && !this.error;
    }

    get hasError() {
        return !!this.error;
    }

    get hasSolicitacoes() {
        return this.solicitacoes.length > 0;
    }

    get hasSaldoSemSolicitacoes() {
        return this.hasSaldo && !this.hasSolicitacoes;
    }

    get diasDireito() {
        return this.saldo ? this.saldo.Dias_Direito__c : 0;
    }

    get diasTirados() {
        return this.saldo ? this.saldo.Dias_Tirados__c : 0;
    }

    get diasDisponiveis() {
        return this.saldo ? this.saldo.Dias_Disponiveis__c : 0;
    }

    get regime() {
        return this.saldo ? this.saldo.Regime_Contratacao__c : '';
    }

    get concessivoFim() {
        return this.saldo ? this.saldo.Periodo_Concessivo_Fim__c : '';
    }

    get percent() {
        if (!this.diasDireito) return 0;
        return Math.round((this.diasTirados / this.diasDireito) * 100);
    }

    get progressStyle() {
        return `--progress: ${this.percent}%;`;
    }

    get badgeVariant() {
        if (this.percent >= 80) return 'slds-theme_warning';
        if (this.percent >= 100) return 'slds-theme_error';
        return 'slds-theme_success';
    }

    getStatusLabel(solicitacao) {
        const aprovacao = solicitacao.Aprovacao_Gestor__c;
        if (aprovacao === 'Pendente') {
            return 'Pendente de aprovação';
        }
        if (aprovacao === 'Aprovado') {
            return 'Aprovada pelo gestor';
        }
        if (aprovacao === 'Reprovado') {
            return 'Reprovada pelo gestor';
        }
        return solicitacao.Status || 'Sem status';
    }

    getStatusClass(solicitacao) {
        const aprovacao = solicitacao.Aprovacao_Gestor__c;
        if (aprovacao === 'Aprovado') {
            return 'request-status request-status_approved';
        }
        if (aprovacao === 'Reprovado') {
            return 'request-status request-status_rejected';
        }
        return 'request-status request-status_pending';
    }

    handleAgendar() {
        const flowApi = 'Agendamento_Ferias_Screen';
        // Rota LEX dedicada ao fluxo (rodape com acoes visivel); standard__flow na App Page pode cortar o rodape.
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/lightning/flow/${flowApi}`
            }
        });
    }
}
