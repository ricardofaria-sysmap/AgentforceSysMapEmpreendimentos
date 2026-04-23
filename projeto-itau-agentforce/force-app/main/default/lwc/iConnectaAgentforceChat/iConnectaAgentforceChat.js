import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import AGENTFORCE_EMBED from '@salesforce/resourceUrl/AgentforceConversationClientEmbed';

export default class IConnectaAgentforceChat extends LightningElement {
    @api agentId;
    @api agentLabel;
    @api loAppId;
    @api floatingLauncher = false;
    @api panelHeight = '520px';
    @api panelWidth = '100%';
    /** Preenchido automaticamente em Record Pages; reservado para contexto futuro do agente. */
    @api recordId;

    phase = 'idle';
    loadErrorMessage;
    embedErrorMessage;
    _embedResult;
    _started;

    connectedCallback() {
        this._start();
    }

    disconnectedCallback() {
        this._teardown();
    }

    get showNoAgent() {
        return this.phase === 'no-agent';
    }

    get showStub() {
        return this.phase === 'stub';
    }

    get showLoadError() {
        return this.phase === 'load-error';
    }

    get showEmbedError() {
        return this.phase === 'embed-error';
    }

    get shellClass() {
        const hide =
            this.showNoAgent || this.showStub || this.showLoadError || this.showEmbedError;
        return hide ? 'iac-shell iac-shell_hidden' : 'iac-shell';
    }

    async _start() {
        if (this._started) {
            return;
        }
        this._started = true;

        const trimmedId = this.agentId ? String(this.agentId).trim() : '';
        if (!trimmedId) {
            this.phase = 'no-agent';
            return;
        }

        try {
            await loadScript(this, AGENTFORCE_EMBED);
        } catch (e) {
            this.loadErrorMessage = this._messageFromError(e);
            this.phase = 'load-error';
            return;
        }

        if (window.__AGENTFORCE_CONVERSATION_CLIENT_STUB__) {
            this.phase = 'stub';
            return;
        }

        if (typeof window.embedAgentforceClient !== 'function') {
            this.loadErrorMessage =
                'O script carregado nao expoe embedAgentforceClient. Verifique o Static Resource.';
            this.phase = 'load-error';
            return;
        }

        await Promise.resolve();
        const shell = this.template.querySelector('.iac-shell');
        if (!shell) {
            this.embedErrorMessage = 'Container de embed nao encontrado.';
            this.phase = 'embed-error';
            return;
        }

        const loAppId = this._trimmedOrUndefined(this.loAppId);
        const floating = this.floatingLauncher === true || this.floatingLauncher === 'true';
        const renderingConfig = floating
            ? { mode: 'floating', showHeaderIcon: true, headerEnabled: true }
            : {
                  mode: 'inline',
                  width: this.panelWidth || '100%',
                  height: this.panelHeight || '520px',
                  headerEnabled: true,
                  showHeaderIcon: false
              };

        try {
            this._embedResult = window.embedAgentforceClient({
                container: shell,
                salesforceOrigin: window.location.origin,
                appId: loAppId,
                agentforceClientConfig: {
                    agentId: trimmedId,
                    agentLabel: this._trimmedOrUndefined(this.agentLabel),
                    renderingConfig
                }
            });
            this.phase = 'ready';
        } catch (e) {
            this.embedErrorMessage = this._messageFromError(e);
            this.phase = 'embed-error';
        }
    }

    _teardown() {
        const shell = this.template.querySelector('.iac-shell');
        if (shell) {
            while (shell.firstChild) {
                shell.removeChild(shell.firstChild);
            }
        }
        this._embedResult = undefined;
    }

    _trimmedOrUndefined(value) {
        if (value === undefined || value === null) {
            return undefined;
        }
        const s = String(value).trim();
        return s ? s : undefined;
    }

    _messageFromError(e) {
        if (!e) {
            return 'Erro desconhecido.';
        }
        if (typeof e === 'string') {
            return e;
        }
        if (e.body && e.body.message) {
            return e.body.message;
        }
        if (e.message) {
            return e.message;
        }
        return 'Erro desconhecido.';
    }
}
