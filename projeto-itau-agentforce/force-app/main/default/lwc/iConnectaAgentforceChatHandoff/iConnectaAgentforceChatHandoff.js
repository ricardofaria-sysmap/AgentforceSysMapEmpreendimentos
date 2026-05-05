import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import USER_ID from '@salesforce/user/Id';
import AGENTFORCE_EMBED from '@salesforce/resourceUrl/AgentforceConversationClientEmbed';

const CHANNEL = '/event/Handoff_Calendario_RH__e';

export default class IConnectaAgentforceChatHandoff extends LightningElement {
    @api agentId;
    @api agentLabel;
    @api loAppId;
    @api panelHeight = '420px';
    @api panelWidth = '100%';

    @api saldoFeriasId;
    @api mostrarCalendario = false;
    @api inicioFerias;
    @api retornoFerias;

    handoffMensagem;
    phase = 'idle';
    loadErrorMessage;
    embedErrorMessage;
    _embedResult;
    _started;
    _diagnosticsAttached = false;
    _diagnosticCleanups = [];
    _subscription;
    _subscribed = false;
    _empErrorBound = false;

    connectedCallback() {
        this._start();
        this._subscribePlatformEvent();
    }

    disconnectedCallback() {
        this._unsubscribePlatformEvent();
        this._teardown();
    }

    get showHandoffBanner() {
        return Boolean(this.handoffMensagem);
    }

    get showCalendarPicker() {
        return Boolean(this.mostrarCalendario && this.saldoFeriasId);
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
        const hide = this.showNoAgent || this.showStub || this.showLoadError || this.showEmbedError;
        return hide ? 'iach-shell iach-shell_hidden' : 'iach-shell';
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
        const shell = this.template.querySelector('.iach-shell');
        if (!shell) {
            this.embedErrorMessage = 'Container de embed nao encontrado.';
            this.phase = 'embed-error';
            return;
        }

        try {
            this._embedResult = window.embedAgentforceClient({
                container: shell,
                salesforceOrigin: window.location.origin,
                appId: this._trimmedOrUndefined(this.loAppId),
                agentforceClientConfig: {
                    agentId: trimmedId,
                    agentLabel: this._trimmedOrUndefined(this.agentLabel),
                    styleTokens: {
                        containerBackground: '#fff7ef',
                        headerBlockBackground: '#ec7000',
                        headerBlockTextColor: '#ffffff',
                        headerBlockBorderBottomColor: '#003399',
                        headerBlockBorderBottomWidth: '3px',
                        headerBlockBorderBottomStyle: 'solid',
                        headerBlockFontWeight: '800',
                        headerBlockIconColor: '#ffffff',
                        messageBlockInboundBackgroundColor: '#fff3e5',
                        messageBlockInboundTextColor: '#1f1f1f',
                        messageBlockOutboundBackgroundColor: '#003399',
                        messageBlockOutboundTextColor: '#ffffff',
                        messageInputFooterSendButton: '#ec7000',
                        messageInputFooterSendButtonHoverColor: '#c95f00',
                        messageInputSendButtonIconColor: '#ffffff',
                        messageInputFooterBorderFocusColor: '#ec7000',
                        messageInputFocusShadow: '0 0 0 2px rgba(236, 112, 0, 0.18)',
                        messageInputBorderRadius: '999px'
                    },
                    renderingConfig: {
                        mode: 'inline',
                        width: this.panelWidth || '100%',
                        height: this.panelHeight || '420px',
                        headerEnabled: true,
                        showHeaderIcon: true
                    }
                }
            });
            this.phase = 'ready';
            this._attachRuntimeDiagnostics();
        } catch (e) {
            this.embedErrorMessage = this._messageFromError(e);
            this.phase = 'embed-error';
        }
    }

    _teardown() {
        for (const cleanup of this._diagnosticCleanups) {
            try {
                cleanup();
            } catch {
                // no-op
            }
        }
        this._diagnosticCleanups = [];
        this._diagnosticsAttached = false;
        const shell = this.template.querySelector('.iach-shell');
        if (shell) {
            while (shell.firstChild) {
                shell.removeChild(shell.firstChild);
            }
        }
        this._embedResult = undefined;
        this._started = false;
    }

    _subscribePlatformEvent() {
        if (this._subscribed) {
            return;
        }
        this._subscribed = true;

        if (!this._empErrorBound) {
            this._empErrorBound = true;
            onError((err) => {
                console.warn('[iConnectaAgentforceChatHandoff] empApi error', err);
            });
        }

        const handler = (response) => this._onHandoffEvent(response);
        subscribe(CHANNEL, -1, handler)
            .then((sub) => {
                this._subscription = sub;
            })
            .catch((err) => {
                console.warn('[iConnectaAgentforceChatHandoff] failed to subscribe', err);
                this._subscribed = false;
            });
    }

    _unsubscribePlatformEvent() {
        const sub = this._subscription;
        this._subscription = undefined;
        this._subscribed = false;
        if (!sub) {
            return;
        }
        try {
            unsubscribe(sub, () => {});
        } catch (err) {
            console.warn('[iConnectaAgentforceChatHandoff] unsubscribe failed', err);
        }
    }

    _onHandoffEvent(response) {
        const payload = response && response.data && response.data.payload;
        if (!payload) {
            return;
        }
        if (!this._matchesCurrentUser(payload.User_Id__c)) {
            return;
        }

        if (typeof payload.Mensagem__c === 'string' && payload.Mensagem__c.trim()) {
            this.handoffMensagem = payload.Mensagem__c.trim();
        } else {
            this.handoffMensagem =
                'Calendario liberado abaixo do chat. Selecione a data de inicio e a data de retorno.';
        }

        if (!this.mostrarCalendario) {
            this.mostrarCalendario = true;
            this.dispatchEvent(new FlowAttributeChangeEvent('mostrarCalendario', true));
        }
    }

    _matchesCurrentUser(eventUserId) {
        if (!eventUserId || !USER_ID) {
            return false;
        }
        return String(eventUserId).substring(0, 15) === String(USER_ID).substring(0, 15);
    }

    handleRangeChange(event) {
        const detail = (event && event.detail) || {};
        const inicio = detail.inicio || null;
        const retorno = detail.retorno || null;
        this.inicioFerias = inicio;
        this.retornoFerias = retorno;
        this.dispatchEvent(new FlowAttributeChangeEvent('inicioFerias', inicio));
        this.dispatchEvent(new FlowAttributeChangeEvent('retornoFerias', retorno));
    }

    @api
    validate() {
        if (!this.mostrarCalendario) {
            return { isValid: true };
        }
        if (!this.saldoFeriasId) {
            return {
                isValid: false,
                errorMessage:
                    'Nao ha saldo de ferias vigente no sistema para carregar o calendario. O assistente ja pode ter explicado: fale com o RH ou continue sem agendar (feche o fluxo).'
            };
        }
        const picker = this.template.querySelector('c-ferias-date-range-picker');
        if (picker && typeof picker.validate === 'function') {
            return picker.validate();
        }
        return { isValid: true };
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

    _attachRuntimeDiagnostics() {
        if (this._diagnosticsAttached) {
            return;
        }
        const loApp = this._embedResult?.loApp;
        const chatClientComponent = this._embedResult?.chatClientComponent;
        if (!loApp) {
            return;
        }
        this._diagnosticsAttached = true;

        const bind = (target, eventName) => {
            const handler = (event) => {
                const detail = event?.detail
                    ? {
                          message: event.detail.message,
                          type: event.detail.type,
                          originalError: event.detail.originalError?.message
                      }
                    : undefined;
                if (eventName.includes('error')) {
                    const runtimeMsg =
                        detail?.message ||
                        detail?.originalError ||
                        'Falha do Lightning Out / Agentforce Conversation Client.';
                    this.embedErrorMessage = runtimeMsg;
                    this.phase = 'embed-error';
                }
            };
            target.addEventListener(eventName, handler);
            this._diagnosticCleanups.push(() => target.removeEventListener(eventName, handler));
        };

        bind(loApp, 'lo.application.ready');
        bind(loApp, 'lo.application.error');
        bind(loApp, 'lo.iframe.error');
        bind(loApp, 'lo.component.error');

        if (chatClientComponent) {
            bind(chatClientComponent, 'accready');
        }
    }
}
