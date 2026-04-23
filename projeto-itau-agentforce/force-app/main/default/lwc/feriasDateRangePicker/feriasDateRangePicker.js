import { LightningElement, api, wire, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getCalendarContext from '@salesforce/apex/FeriasDateRulesService.getCalendarContext';

function fromIsoLocal(isoStr) {
    if (!isoStr) {
        return null;
    }
    if (isoStr instanceof Date) {
        return new Date(isoStr.getFullYear(), isoStr.getMonth(), isoStr.getDate(), 12, 0, 0);
    }
    const head = String(isoStr).split('T')[0];
    const [y, m, d] = head.split('-').map((x) => parseInt(x, 10));
    if (!y || !m || !d) {
        return null;
    }
    return new Date(y, m - 1, d, 12, 0, 0);
}

function toIsoLocal(dt) {
    if (!dt) {
        return null;
    }
    const y = dt.getFullYear();
    const mo = String(dt.getMonth() + 1).padStart(2, '0');
    const da = String(dt.getDate()).padStart(2, '0');
    return `${y}-${mo}-${da}`;
}

function addDaysLocal(isoStr, n) {
    const d = fromIsoLocal(isoStr);
    d.setDate(d.getDate() + n);
    return toIsoLocal(d);
}

function compareIso(a, b) {
    if (a === b) {
        return 0;
    }
    return a < b ? -1 : 1;
}

function normalizeFlowDate(v) {
    if (v == null || v === undefined) {
        return null;
    }
    if (typeof v === 'string') {
        return v.length >= 10 ? v.substring(0, 10) : v;
    }
    if (typeof v === 'object' && v.year != null && v.month != null && v.day != null) {
        return `${v.year}-${String(v.month).padStart(2, '0')}-${String(v.day).padStart(2, '0')}`;
    }
    return null;
}

function flowDateToIso(v) {
    const n = normalizeFlowDate(v);
    if (n) {
        return n;
    }
    if (v instanceof Date) {
        return toIsoLocal(v);
    }
    return null;
}

function monthMatrix(year, monthIndex) {
    const first = new Date(year, monthIndex, 1, 12, 0, 0);
    const jsDow = first.getDay();
    const sfFirst = jsDow === 0 ? 1 : jsDow + 1;
    const pad = sfFirst - 1;
    const dim = new Date(year, monthIndex + 1, 0, 12, 0, 0).getDate();
    const cells = [];
    let i = 0;
    for (; i < pad; i++) {
        cells.push({ key: `p-${i}`, empty: true });
    }
    for (let day = 1; day <= dim; day++) {
        const cellDate = new Date(year, monthIndex, day, 12, 0, 0);
        cells.push({
            key: `d-${day}`,
            empty: false,
            label: String(day),
            iso: toIsoLocal(cellDate)
        });
    }
    while (cells.length % 7 !== 0) {
        cells.push({ key: `t-${i}`, empty: true });
        i++;
    }
    while (cells.length < 42) {
        cells.push({ key: `x-${i}`, empty: true });
        i++;
    }
    return cells.slice(0, 42);
}

export default class FeriasDateRangePicker extends LightningElement {
    @api saldoFeriasId;

    @api inicioFerias;
    @api retornoFerias;

    _ctx;
    _blocked = new Set();
    _error;

    @track _viewYearStart = new Date().getFullYear();
    @track _viewMonthStart = new Date().getMonth();
    @track _viewYearEnd = new Date().getFullYear();
    @track _viewMonthEnd = new Date().getMonth();

    @wire(getCalendarContext, { saldoFeriasId: '$saldoFeriasId' })
    wiredContext({ data, error }) {
        if (data) {
            this._ctx = data;
            this._blocked = new Set(data.blockedStartIsoDates || []);
            this._error = undefined;
            this._syncViewsToSelection();
        } else if (error) {
            this._ctx = undefined;
            this._blocked = new Set();
            this._error = error.body && error.body.message ? error.body.message : 'Nao foi possivel carregar o calendario.';
        }
    }

    _syncViewsToSelection() {
        if (this.inicioFerias) {
            const di = fromIsoLocal(this.inicioFerias);
            this._viewYearStart = di.getFullYear();
            this._viewMonthStart = di.getMonth();
        }
        if (this.retornoFerias) {
            const dr = fromIsoLocal(this.retornoFerias);
            this._viewYearEnd = dr.getFullYear();
            this._viewMonthEnd = dr.getMonth();
        } else if (this.inicioFerias) {
            const di = fromIsoLocal(this.inicioFerias);
            this._viewYearEnd = di.getFullYear();
            this._viewMonthEnd = di.getMonth();
        }
    }

    get hasError() {
        return !!this._error;
    }

    get errorMessage() {
        return this._error;
    }

    get minStartIso() {
        return this._ctx ? normalizeFlowDate(this._ctx.minStartDate) : null;
    }

    get maxStartIso() {
        return this._ctx ? normalizeFlowDate(this._ctx.maxStartDate) : null;
    }

    get concessivoEndIso() {
        return this._ctx ? normalizeFlowDate(this._ctx.concessivoEnd) : null;
    }

    get diasDisponiveis() {
        return this._ctx ? this._ctx.diasDisponiveis : null;
    }

    get monthTitleStart() {
        return new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' }).format(
            new Date(this._viewYearStart, this._viewMonthStart, 1)
        );
    }

    get monthTitleEnd() {
        return new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' }).format(
            new Date(this._viewYearEnd, this._viewMonthEnd, 1)
        );
    }

    get gridStart() {
        return this._decorateGrid(monthMatrix(this._viewYearStart, this._viewMonthStart), 'start');
    }

    get gridEnd() {
        return this._decorateGrid(monthMatrix(this._viewYearEnd, this._viewMonthEnd), 'end');
    }

    get startWeeks() {
        return this._toWeekRows(this.gridStart);
    }

    get endWeeks() {
        return this._toWeekRows(this.gridEnd);
    }

    _toWeekRows(flat) {
        const rows = [];
        for (let r = 0; r < 6; r++) {
            rows.push({ key: `sr-${r}`, cells: flat.slice(r * 7, r * 7 + 7) });
        }
        return rows;
    }

    get showEndPicker() {
        return !!this.inicioFerias;
    }

    get minEndIso() {
        const ini = flowDateToIso(this.inicioFerias);
        if (!ini) {
            return null;
        }
        return addDaysLocal(ini, 4);
    }

    get maxEndIso() {
        const ini = flowDateToIso(this.inicioFerias);
        if (!this._ctx || !ini) {
            return null;
        }
        const dias = Math.floor(Number(this._ctx.diasDisponiveis || 0));
        const dMax = dias > 0 ? addDaysLocal(ini, dias - 1) : addDaysLocal(ini, 4);
        const cIso = normalizeFlowDate(this._ctx.concessivoEnd);
        if (!cIso) {
            return dMax;
        }
        return compareIso(dMax, cIso) <= 0 ? dMax : cIso;
    }

    _decorateGrid(matrix, phase) {
        const minS = this.minStartIso;
        const maxS = this.maxStartIso;
        const minE = this.minEndIso;
        const maxE = this.maxEndIso;
        return matrix.map((cell) => {
            if (cell.empty) {
                return { ...cell, disabled: true, selected: false, classes: 'cell cell--empty' };
            }
            const iso = cell.iso;
            const inicioIso = flowDateToIso(this.inicioFerias);
            const retornoIso = flowDateToIso(this.retornoFerias);
            let disabled = false;
            let selected = false;
            if (phase === 'start') {
                disabled =
                    !this._ctx ||
                    !minS ||
                    !maxS ||
                    compareIso(iso, minS) < 0 ||
                    compareIso(iso, maxS) > 0 ||
                    this._blocked.has(iso);
                selected = inicioIso === iso;
            } else {
                disabled =
                    !this.inicioFerias ||
                    !minE ||
                    !maxE ||
                    compareIso(iso, minE) < 0 ||
                    compareIso(iso, maxE) > 0;
                selected = retornoIso === iso;
            }
            const classes = `cell${disabled ? ' cell--disabled' : ''}${selected ? ' cell--selected' : ''}`;
            return { ...cell, disabled, selected, classes };
        });
    }

    handlePrevStart() {
        let m = this._viewMonthStart - 1;
        let y = this._viewYearStart;
        if (m < 0) {
            m = 11;
            y--;
        }
        this._viewYearStart = y;
        this._viewMonthStart = m;
    }

    handleNextStart() {
        let m = this._viewMonthStart + 1;
        let y = this._viewYearStart;
        if (m > 11) {
            m = 0;
            y++;
        }
        this._viewYearStart = y;
        this._viewMonthStart = m;
    }

    handlePrevEnd() {
        let m = this._viewMonthEnd - 1;
        let y = this._viewYearEnd;
        if (m < 0) {
            m = 11;
            y--;
        }
        this._viewYearEnd = y;
        this._viewMonthEnd = m;
    }

    handleNextEnd() {
        let m = this._viewMonthEnd + 1;
        let y = this._viewYearEnd;
        if (m > 11) {
            m = 0;
            y++;
        }
        this._viewYearEnd = y;
        this._viewMonthEnd = m;
    }

    handlePickStart(event) {
        const iso = event.currentTarget.dataset.iso;
        const disabled = event.currentTarget.dataset.disabled === 'true';
        if (!iso || disabled) {
            return;
        }
        this.inicioFerias = iso;
        this.retornoFerias = null;
        this._syncViewsToSelection();
        this.dispatchEvent(new FlowAttributeChangeEvent());
    }

    handlePickEnd(event) {
        const iso = event.currentTarget.dataset.iso;
        const disabled = event.currentTarget.dataset.disabled === 'true';
        if (!iso || disabled) {
            return;
        }
        this.retornoFerias = iso;
        this._syncViewsToSelection();
        this.dispatchEvent(new FlowAttributeChangeEvent());
    }

    @api
    validate() {
        if (this._error) {
            return { isValid: false, errorMessage: this._error };
        }
        if (!this.inicioFerias || !this.retornoFerias) {
            return { isValid: false, errorMessage: 'Selecione a data de inicio e a data de retorno no calendario.' };
        }
        const retIso = flowDateToIso(this.retornoFerias);
        if (this._ctx && this.maxEndIso && retIso && compareIso(retIso, this.maxEndIso) > 0) {
            return { isValid: false, errorMessage: 'A data de retorno excede o saldo ou o periodo concessivo.' };
        }
        return { isValid: true };
    }
}
