import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import getSaldoVigente from '@salesforce/apex/SaldoFeriasController.getSaldoVigente';

export default class SaldoFeriasCard extends NavigationMixin(LightningElement) {
    userId = USER_ID;
    saldo;
    loading = true;
    error;

    @wire(getSaldoVigente)
    wiredSaldo({ error, data }) {
        this.loading = false;
        if (data) {
            this.saldo = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.saldo = undefined;
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
