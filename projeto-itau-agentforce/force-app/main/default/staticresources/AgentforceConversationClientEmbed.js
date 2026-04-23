(() => {
  // node_modules/@lightning-out/application/dist/index.esm.js
  var events = {
    lo: {
      // public
      application: {
        ready: "lo.application.ready",
        error: "lo.application.error",
        logout: "lo.application.logout"
      },
      // public
      component: {
        ready: "lo.component.ready",
        error: "lo.component.error"
      },
      // internal
      iframe: {
        load: "lo.iframe.load",
        error: "lo.iframe.error"
      }
    }
  };
  var messages = {
    lo: {
      "height-change": "lo.height-change",
      // unused
      addEventListener: "lo.addEventListener",
      dispatchEvent: "lo.dispatchEvent",
      removeEventListener: "lo.removeEventListener",
      error: "lo.error",
      getComponentData: "lo.getComponentData",
      loaded: "lo.loaded",
      ready: "lo.ready",
      setComponentData: "lo.setComponentData",
      setComponentProps: "lo.setComponentProps"
    }
  };
  var logLevels = {
    error: 0,
    warn: 1,
    info: 2,
    debug: 3,
    trace: 4
  };
  var Logger = class _Logger {
    static #prefix = "LO2";
    static #level = "error";
    #branding;
    static set level(level) {
      this.#level = level;
    }
    static set prefix(prefix) {
      this.#prefix = prefix;
    }
    // This string appears first in the console, it can be used for filtering messages
    get brand() {
      return `${_Logger.#prefix}:${this.#branding}:`;
    }
    constructor(branding) {
      if (typeof branding === "string") {
        this.#branding = branding;
      } else {
        this.#branding = branding.constructor?.name;
      }
    }
    error(...args) {
      if (logLevels.error <= logLevels[_Logger.#level]) {
        console.error(this.brand, ...args);
      }
    }
    warn(...args) {
      if (logLevels.warn <= logLevels[_Logger.#level]) {
        console.warn(this.brand, ...args);
      }
    }
    info(...args) {
      if (logLevels.info <= logLevels[_Logger.#level]) {
        console.info(this.brand, ...args);
      }
    }
    debug(...args) {
      if (logLevels.debug <= logLevels[_Logger.#level]) {
        console.debug(this.brand, ...args);
      }
    }
    trace(...args) {
      if (logLevels.trace <= logLevels[_Logger.#level]) {
        console.trace(this.brand, ...args);
      }
    }
  };
  var logger$4 = new Logger("LightningOutError");
  var LightningOutError = class {
    #eventTarget;
    #branding;
    constructor(branding) {
      if (typeof branding === "string") {
        this.#branding = branding;
      } else {
        this.#branding = branding.constructor?.name;
      }
      if (typeof branding.dispatchEvent === "function") {
        this.#eventTarget = branding;
      }
    }
    #branded(message) {
      return `${this.#branding}: ${message}`;
    }
    create(error) {
      const message = typeof error === "string" ? error : error.message;
      return new Error(this.#branded(message));
    }
    dispatch(type, error) {
      const message = typeof error === "string" ? error : error.message || error.detail?.message;
      if (this.#eventTarget) {
        const detail = error.detail || {
          message: this.#branded(message),
          originalError: error
        };
        const loErrorEvent = new CustomEvent(type, { detail });
        this.#eventTarget.dispatchEvent(loErrorEvent);
        logger$4.error(`${this.#branded("dispatched error")} -> ${type}: ${message}`);
      } else {
        logger$4.error(`${this.#branded("unable to dispatch error on a non-EventTarget object")} -> ${type}: ${message}`);
      }
    }
  };
  var loError = new LightningOutError("LightningOutUtils");
  function kebabToCamel(attrName) {
    return attrName.replace(/-([a-z])/g, (_, char) => char.toUpperCase());
  }
  function camelToKebab(propName) {
    return propName.replace(/([A-Z])/g, "-$1").toLowerCase();
  }
  function camelToSnake(propName) {
    return propName.replace(/([A-Z])/g, "_$1").toLowerCase();
  }
  function snakeToCamel(snakeName) {
    return snakeName.replace(/_([a-z])/g, (_, char) => char.toUpperCase());
  }
  function elementNameToStandardName(kebabName, isAura = false) {
    const nsSepIdx = kebabName.indexOf("-");
    if (nsSepIdx === -1) {
      throw loError.create(`elementNameToStandardName: ${kebabName} is not a valid custom element name.`);
    }
    const ns = snakeToCamel(kebabName.slice(0, nsSepIdx));
    const name = kebabToCamel(kebabName.slice(nsSepIdx + 1));
    const separator = isAura ? ":" : "/";
    return `${ns}${separator}${name}`;
  }
  function standardNameToElementName(standardName) {
    const separator = standardName.includes(":") ? ":" : "/";
    const sepIdx = standardName.indexOf(separator);
    if (sepIdx === -1) {
      throw loError.create(`standardNameToElementName: ${standardName} is not a valid component name.`);
    }
    const ns = camelToSnake(standardName.slice(0, sepIdx));
    const name = camelToKebab(standardName.slice(sepIdx + 1));
    return `${ns}-${name}`;
  }
  function isStandardName(name) {
    return name.includes("/") || name.includes(":");
  }
  function processPropertyChanges(element, changes) {
    const processed = Object.entries(changes).map((entry) => {
      let [key, value] = entry;
      const mirror = key.split("dataMirror");
      if (mirror.length === 2 && mirror[0] === "") {
        key = mirror[1].charAt(0).toLowerCase() + mirror[1].slice(1);
      }
      const callbackName = `_propertyChanged_${key}`;
      if (typeof element[callbackName] === "function") {
        const callback = element[callbackName];
        value = callback(value);
      }
      return [key, value];
    });
    return Object.fromEntries(processed);
  }
  function getUrlData(url) {
    const urlData = {};
    const paramsData = (params) => {
      const paramsData2 = {};
      for (const [key, value] of params.entries()) {
        paramsData2[key] = value;
      }
      return paramsData2;
    };
    urlData.url = url.origin + url.pathname;
    urlData.urlParams = paramsData(url.searchParams);
    if (url.pathname === "/secur/frontdoor.jsp") {
      const paramName = urlData.urlParams["otp"] ? "startURL" : "retURL";
      const startURL = new URL(urlData.urlParams[paramName], "http://dummy.com");
      urlData.urlParams[paramName] = {
        url: startURL.pathname,
        urlParams: paramsData(startURL.searchParams)
      };
    }
    return urlData;
  }
  function getUUID() {
    return Math.floor(Math.random() * Number.MAX_SAFE_INTEGER).toString(36);
  }
  var logger$3 = new Logger("LightningOutIFrame");
  var LightningOutIFrame = class {
    #parentElement;
    #isVisible;
    #parentError;
    #hiddenStyle = "display:none";
    #visibleStyle = "border:0px; width:100%; height:100%; overflow:auto;";
    #shadowRoot;
    #element;
    #window;
    #origin;
    #endpoint;
    #timeoutID;
    constructor(iframeConfig) {
      this.#parentElement = iframeConfig.parentElement;
      this.#isVisible = iframeConfig.isVisible;
      this.#parentError = new LightningOutError(iframeConfig.parentElement);
    }
    get iframeReady() {
      return !!this.#window && !!this.#origin;
    }
    get iframeElement() {
      return this.#element;
    }
    #config(window2, origin) {
      this.#window = window2;
      this.#origin = origin;
    }
    #messageListener = (event) => {
      if (event.data.id !== this.#parentElement._uuid) {
        return;
      }
      logger$3.debug("#messageListener:", `parentElement._uuid: ${this.#parentElement._uuid}`, `parentElement.localName: ${this.#parentElement.localName}`, JSON.stringify(event.data));
      switch (event.data.type) {
        case messages.lo.loaded: {
          this.#timeoutID = clearTimeout(this.#timeoutID);
          this.#config(event.source, event.origin);
          this.#parentElement.dispatchEvent(new CustomEvent(events.lo.iframe.load, {
            detail: event.origin
          }));
          break;
        }
      }
    };
    #init() {
      if (!this.#element) {
        const iframe = window.document.createElement("iframe");
        iframe.name = "lightning_af";
        iframe.sandbox = [
          "allow-downloads",
          "allow-forms",
          "allow-popups",
          "allow-same-origin",
          "allow-scripts",
          "allow-top-navigation-by-user-activation"
        ].join(" ");
        iframe.style.cssText = this.#isVisible ? this.#visibleStyle : this.#hiddenStyle;
        this.#element = iframe;
        this.#shadowRoot = this.#parentElement.attachShadow({
          mode: "closed"
        });
        this.#shadowRoot.appendChild(this.#element);
        iframe.addEventListener("load", this.#loaded);
        window.addEventListener("message", this.#messageListener);
      }
      return this.#element;
    }
    load(endpoint) {
      const iframe = this.#init();
      this.#endpoint = new URL(endpoint);
      logger$3.debug(`#loadIframe: endpoint =`, getUrlData(this.#endpoint));
      this.#config(void 0, void 0);
      iframe.src = endpoint;
      if (!this.#isVisible && localStorage.getItem(`${logger$3.brand}load:window.open`)) {
        window.open(endpoint);
      }
    }
    #loaded = () => {
      const timeout = 60 * 1e3;
      if (this.#timeoutID) {
        clearTimeout(this.#timeoutID);
      }
      this.#timeoutID = setTimeout(() => {
        if (!this.iframeReady) {
          const message = "Error: Unknown error, unable to load the iframe.";
          this.#parentError.dispatch(events.lo.iframe.error, message);
          this.#showErrorMessage(message);
        }
      }, timeout);
    };
    destroy() {
      if (this.#shadowRoot) {
        this.#shadowRoot.innerHTML = "";
      }
      if (this.#element) {
        this.#element.remove();
      }
      this.#shadowRoot = void 0;
      this.#element = void 0;
      this.#config(void 0, void 0);
    }
    #showErrorMessage(message) {
      if (this.#isVisible && this.#endpoint) {
        const url = new URL("/lightning/lightning.out.message.html", this.#endpoint.origin);
        url.search = new URLSearchParams({
          loAppOrigin: window.location.origin,
          parentElementId: this.#parentElement._uuid,
          message
        }).toString();
        this.load(url.href);
      }
    }
    postMessage(message) {
      if (this.#window && this.#origin) {
        logger$3.debug("postMessage:", `parentElement: ${this.#parentElement._uuid}`, JSON.stringify(message));
        try {
          this.#window.postMessage(message, this.#origin);
        } catch (err) {
          const message2 = `postMessage error: ${err}`;
          this.#parentError.dispatch(events.lo.iframe.error, message2);
          throw this.#parentError.create(message2);
        }
      } else {
        throw this.#parentError.create("Error attempting to postMessage on an iframe that is not ready.");
      }
    }
  };
  var logger$2 = new Logger("PropertyObserver");
  var PropertyObserver = class {
    /**
     * The HTML element whose properties and attributes are being observed.
     */
    _el;
    /**
     * The callback function to invoke when properties/attributes change.
     */
    _cb;
    /**
     * A cache of the last known values of observed properties.
     * Keys are property names (camelCase), values are their current values.
     */
    _cache;
    /**
     * The callback to determine if a property should be observed.
     */
    _shouldObserve;
    /**
     * Set of property names that we've installed getter/setter interceptors for.
     */
    _interceptedProps;
    /**
     * Map of original property descriptors that we've replaced.
     */
    _originalDescriptors;
    /**
     * The MutationObserver instance watching for attribute changes.
     */
    _observer;
    /**
     * Flag to track if we have a pending microtask for batched changes.
     */
    _changesPending;
    /**
     * Accumulated changes waiting to be reported in the next microtask.
     */
    _pendingChanges;
    /**
     * Map of attribute names that don't follow standard kebab-case to camelCase conversion.
     * Maps attribute name -> property name for special cases.
     */
    _attributeExceptions = /* @__PURE__ */ new Map([
      ["for", "htmlFor"],
      ["class", "className"],
      ["formnovalidate", "formNoValidate"],
      ["readonly", "readOnly"],
      ["maxlength", "maxLength"],
      ["minlength", "minLength"],
      ["contenteditable", "contentEditable"],
      ["spellcheck", "spellcheck"],
      // This one actually matches, but explicitly included for clarity
      ["novalidate", "noValidate"],
      ["autofocus", "autofocus"],
      // This one actually matches too
      ["autocomplete", "autocomplete"],
      // And this one
      ["crossorigin", "crossOrigin"]
    ]);
    /**
     * Creates an instance of PropertyObserver.
     *
     * @param target The DOM element whose properties and attributes you want to observe.
     * @param callback
     *   The function to be invoked when one or more properties/attributes change.
     *   This function receives a single argument: an object where keys are property names
     *   (in camelCase) and values are their new values.
     *   This callback is called synchronously once upon initialization with all initial values,
     *   then asynchronously (batched via microtask) for subsequent changes.
     * @throws {TypeError} If `target` is not a DOM Element or `callback` is not a function.
     */
    constructor(target, callback, shouldObserve) {
      if (!(target instanceof Element)) {
        throw new TypeError("Target must be a DOM Element");
      }
      if (typeof callback !== "function") {
        throw new TypeError("Callback must be a function");
      }
      if (shouldObserve && typeof shouldObserve !== "function") {
        throw new TypeError("shouldObserve callback must be a function");
      }
      const shouldObserveDefault = (propName, isStandard) => {
        return isStandard === false;
      };
      this._el = target;
      this._cb = callback;
      this._cache = /* @__PURE__ */ new Map();
      this._shouldObserve = shouldObserve || shouldObserveDefault;
      this._interceptedProps = /* @__PURE__ */ new Set();
      this._originalDescriptors = /* @__PURE__ */ new Map();
      this._changesPending = false;
      this._pendingChanges = {};
      this._initialScan();
      this._setupMutationObserver();
    }
    /**
     * Disconnects the observer and restores original property descriptors.
     * This stops observing changes and cleans up any modifications made to the element.
     */
    disconnect() {
      if (this._observer) {
        this._observer.disconnect();
      }
      for (const [propName, descriptor] of this._originalDescriptors) {
        Object.defineProperty(this._el, propName, descriptor);
      }
      this._cache.clear();
      this._interceptedProps.clear();
      this._originalDescriptors.clear();
      this._pendingChanges = {};
      this._changesPending = false;
    }
    /**
     * Performs the initial scan of the element to detect non-standard attributes
     * and properties, then calls the callback synchronously with initial values.
     */
    _initialScan() {
      const initialValues = {};
      for (const attr of Array.from(this._el.attributes)) {
        const attrName = attr.name;
        const isStandard = this._isStandardAttribute(attrName);
        if (!this._shouldObserve(attrName, isStandard)) {
          continue;
        }
        const propName = this._attributeNameToPropName(attrName);
        const value = attr.value;
        initialValues[propName] = value;
        this._cache.set(propName, value);
        this._installPropertyInterceptor(propName);
      }
      for (const propName of Object.getOwnPropertyNames(this._el)) {
        const isStandard = this._isStandardProperty(propName);
        if (this._cache.has(propName) || !this._shouldObserve(propName, isStandard)) {
          continue;
        }
        const value = this._el[propName];
        initialValues[propName] = value;
        this._cache.set(propName, value);
        this._installPropertyInterceptor(propName);
      }
      if (Object.keys(initialValues).length > 0) {
        try {
          this._cb(initialValues);
        } catch (e) {
          logger$2.error("Error in initial PropertyObserver callback:", e);
        }
      }
    }
    /**
     * Sets up the MutationObserver to watch for attribute changes.
     */
    _setupMutationObserver() {
      this._observer = new MutationObserver((mutations) => {
        const changes = {};
        for (const mutation of mutations) {
          if (mutation.type === "attributes" && mutation.attributeName) {
            const attrName = mutation.attributeName;
            const isStandard = this._isStandardAttribute(attrName);
            if (!this._shouldObserve(attrName, isStandard)) {
              continue;
            }
            const propName = this._attributeNameToPropName(attrName);
            const newValue = this._el.getAttribute(attrName);
            const cachedValue = this._cache.get(propName);
            if (newValue !== cachedValue) {
              changes[propName] = newValue;
              this._cache.set(propName, newValue);
              if (!this._interceptedProps.has(propName)) {
                this._installPropertyInterceptor(propName);
              }
            }
          }
        }
        if (Object.keys(changes).length > 0) {
          this._batchChanges(changes);
        }
      });
      this._observer.observe(this._el, {
        attributes: true,
        attributeOldValue: false
        // We track old values ourselves
      });
    }
    /**
     * Installs a getter/setter interceptor for a property to detect changes.
     * @param propName The property name to intercept
     */
    _installPropertyInterceptor(propName) {
      if (this._interceptedProps.has(propName)) {
        return;
      }
      const currentDescriptor = Object.getOwnPropertyDescriptor(this._el, propName) || {
        value: this._el[propName],
        writable: true,
        enumerable: true,
        configurable: true
      };
      this._originalDescriptors.set(propName, currentDescriptor);
      const newDescriptor = {
        enumerable: currentDescriptor.enumerable,
        configurable: currentDescriptor.configurable,
        get: currentDescriptor.get || (() => currentDescriptor.value),
        set: (newValue) => {
          const oldValue = this._cache.get(propName);
          if (newValue !== oldValue) {
            if (currentDescriptor.set) {
              currentDescriptor.set.call(this._el, newValue);
            } else {
              currentDescriptor.value = newValue;
            }
            this._cache.set(propName, newValue);
            this._batchChanges({ [propName]: newValue });
          }
        }
      };
      Object.defineProperty(this._el, propName, newDescriptor);
      this._interceptedProps.add(propName);
    }
    /**
     * Batches changes to be reported in the next microtask.
     * @param changes Changes to batch
     */
    _batchChanges(changes) {
      Object.assign(this._pendingChanges, changes);
      if (!this._changesPending) {
        this._changesPending = true;
        queueMicrotask(() => {
          this._changesPending = false;
          const changesToReport = { ...this._pendingChanges };
          this._pendingChanges = {};
          try {
            this._cb(changesToReport);
          } catch (e) {
            logger$2.error("Error in PropertyObserver callback:", e);
          }
        });
      }
    }
    /**
     * Converts an attribute name (kebab-case) to a property name (camelCase).
     * @param attrName The attribute name
     * @returns The property name
     */
    _attributeNameToPropName(attrName) {
      if (this._attributeExceptions.has(attrName)) {
        return this._attributeExceptions.get(attrName);
      }
      return attrName.replace(/-([a-z])/g, (match, letter) => letter.toUpperCase());
    }
    /**
     * Checks if an attribute name is a standard HTML attribute that should be ignored.
     * @param attrName The attribute name (already lowercase per HTML spec)
     * @returns True if it's a standard attribute
     */
    _isStandardAttribute(attrName) {
      if (attrName.startsWith("data-") || attrName.startsWith("aria-") || attrName.startsWith("on")) {
        return true;
      }
      const propName = this._attributeNameToPropName(attrName);
      return this._isStandardProperty(propName);
    }
    /**
     * Checks if a property name corresponds to a standard property that should be ignored.
     * @param propName The property name
     * @returns True if it's a standard property
     */
    _isStandardProperty(propName) {
      return propName in HTMLElement.prototype;
    }
  };
  var Registry = class {
    #loError = new LightningOutError("LightningOutRegistry");
    appToComps = /* @__PURE__ */ new WeakMap();
    compToApp = /* @__PURE__ */ new WeakMap();
    compNameToApp = /* @__PURE__ */ new Map();
    /**
     * Registers a new App instance in the registry.
     * @param app The App instance to register.
     * registered app.
     */
    registerApplication(app) {
      if (!this.appToComps.has(app)) {
        this.appToComps.set(app, /* @__PURE__ */ new Set());
      }
    }
    /**
     * Registers a component name which is owned by a specific App
     * @param name The component name
     * @param app The app that owns the name
     * @throws {LightningOutError} if the name is already registered
     */
    registerComponentName(name, app) {
      if (this.compNameToApp.has(name)) {
        throw this.#loError.create(`"${name}" is already registered to another App.`);
      }
      this.compNameToApp.set(name, app);
    }
    /**
     * Registers a Comp instance and associates it with a parent App.
     * @param comp The Comp instance to register.
     * @param app The parent App instance. (Optional)
     * @returns The parent App
     * @throws {LightningOutError} If the Comp is already registered or if no parent App is found.
     */
    registerComponent(comp, app) {
      if (this.compToApp.has(comp)) {
        throw this.#loError.create("This Comp is already registered to another App.");
      }
      let parentApp = app;
      if (!parentApp) {
        const compName = comp.localName;
        parentApp = this.compNameToApp.get(compName);
        if (!parentApp) {
          throw this.#loError.create(`Could not find a parent App for component "${comp.localName}"`);
        }
      }
      this.appToComps.get(parentApp).add(comp);
      this.compToApp.set(comp, parentApp);
      return parentApp;
    }
    /**
     * Unregister a Comp instance from the registry.
     * @param comp The Comp instance to unregister.
     * @returns `true` if the component was found and unregistered, otherwise `false`.
     */
    unregisterComponent(comp) {
      const app = this.compToApp.get(comp);
      if (!app) {
        return false;
      }
      const comps = this.appToComps.get(app);
      comps?.delete(comp);
      this.compToApp.delete(comp);
      return true;
    }
    /**
     * Retrieves the set of Comps associated with a given App.
     * @param app The App instance for which to retrieve components.
     * @returns A Set of Comp instances associated with the given App.
     * @throws {LightningOutError} If the set of components for the given app cannot be found.
     */
    getComps(app) {
      const comps = this.appToComps.get(app);
      if (!comps) {
        throw this.#loError.create("Unable to find set of LightningOutComponents");
      }
      return comps;
    }
  };
  var registry = new Registry();
  var logger$1 = new Logger("LightningOutComponent");
  var MIRROR = /* @__PURE__ */ new Set([
    "autocapitalize",
    "autocorrect",
    "dir",
    "enterkeyhint",
    "inputmode",
    "lang",
    "spellcheck",
    "style",
    // this is mirrored but only the css variables
    "title",
    "translate"
  ]);
  var ARIA_MIRROR = /* @__PURE__ */ new Set([
    "aria-disabled",
    "aria-hidden",
    "aria-label",
    "aria-live",
    "aria-modal",
    "aria-pressed",
    "aria-valuemax",
    "aria-valuemin",
    "aria-valuenow"
  ]);
  var BLOCK = /* @__PURE__ */ new Set([
    "accesskey",
    "autofocus",
    "draggable",
    "exportparts",
    "hidden",
    "inert",
    "nonce",
    // block for security reasons!
    "part",
    "slot",
    "tabindex"
  ]);
  var ARIA_BLOCK = /* @__PURE__ */ new Set([
    "aria-activedescendant",
    "aria-controls",
    "aria-describedby",
    "aria-details",
    "aria-errormessage",
    "aria-flowto",
    "aria-labelledby",
    "aria-owns"
  ]);
  var LightningOutComponent = class extends HTMLElement {
    _uuid = getUUID();
    _ready = false;
    _standardName = elementNameToStandardName(this.localName);
    // May change during registration
    #parentApp;
    // The parent LightningOutApplication
    #loError = new LightningOutError(this);
    #loIFrame = new LightningOutIFrame({
      parentElement: this,
      isVisible: true
    });
    #propObserver;
    #initialRender = true;
    #eventQueue = [];
    #listenerKeyMap = /* @__PURE__ */ new WeakMap();
    // Seed for generating unique listener keys.
    #listenerKeySeed = 0;
    constructor() {
      super();
      logger$1.trace("constructor: called", `_uuid: ${this._uuid}`);
    }
    getComponentURL() {
      const parentApp = this.#parentApp;
      if (!parentApp) {
        throw this.#loError.create("Undefined parent App!");
      }
      const compURL = parentApp.getComponentURL(this._standardName, this._uuid);
      return compURL;
    }
    _init() {
      if (!this._ready) {
        this.#loIFrame.load(this.getComponentURL().href);
      }
    }
    #messageListener = (event) => {
      if (event.data.id !== this._uuid) {
        return;
      }
      logger$1.debug("#messageListener:", `this._uuid: ${this._uuid}`, `this._standardName: ${this._standardName}`, `event.data: ${JSON.stringify(event.data)}`);
      switch (event.data.type) {
        case messages.lo.ready: {
          while (this.#eventQueue.length) {
            const item = this.#eventQueue.shift();
            if (!item)
              continue;
            if (item.type === "add") {
              this.addEventListener(...item.args);
            } else if (item.type === "remove") {
              this.removeEventListener(...item.args);
            } else if (item.type === "dispatch") {
              this.dispatchEvent(item.event);
            }
          }
          this._ready = true;
          super.dispatchEvent(new CustomEvent(events.lo.component.ready));
          break;
        }
        case messages.lo.getComponentData: {
          this.#propObserver = new PropertyObserver(this, this.#propObserverCallback, this.#shouldObserveCallback);
          break;
        }
        case messages.lo["height-change"]: {
          break;
        }
        case messages.lo.dispatchEvent: {
          const customEvent = new CustomEvent(event.data.name, {
            detail: event.data.detail
          });
          super.dispatchEvent(customEvent);
          break;
        }
        case messages.lo.error: {
          this.#loError.dispatch(events.lo.component.error, event.data.error);
          break;
        }
        default: {
          logger$1.info(`#messageListener:`, `Unknown message received:`, {
            "event.data": event.data
          });
        }
      }
    };
    _propertyChanged_style = (_style) => {
      const cssDeclaration = this.style;
      const cssVars = [];
      for (let i = 0; i < cssDeclaration.length; i += 1) {
        const prop = cssDeclaration.item(i);
        if (prop.startsWith("--")) {
          cssVars.push(`${prop}:${cssDeclaration.getPropertyValue(prop)}`);
        }
      }
      return cssVars.join(";");
    };
    #propObserverCallback = (changes) => {
      const propsToSend = processPropertyChanges(this, changes);
      logger$1.debug("#propObserverCallback:", { changes, propsToSend });
      if (this.#initialRender) {
        this.#initialRender = false;
        this.#loIFrame.postMessage({
          type: messages.lo.setComponentData,
          componentData: {
            id: this._uuid,
            name: this._standardName,
            props: propsToSend
          }
        });
      } else {
        this.#loIFrame.postMessage({
          type: messages.lo.setComponentProps,
          componentProps: propsToSend
        });
      }
    };
    #shouldObserveCallback = (attrOrPropName, isStandard) => {
      const attrName = camelToKebab(attrOrPropName);
      logger$1.debug("#shouldObserveCallback:", { attrOrPropName, attrName, isStandard });
      if (isStandard) {
        if (MIRROR.has(attrName) || ARIA_MIRROR.has(attrName)) {
          return true;
        }
        if (BLOCK.has(attrName) || ARIA_BLOCK.has(attrName) || attrName.startsWith("on")) {
          logger$1.warn(`"${attrName}" will not be mirrored.`);
          return false;
        }
        if (attrName.startsWith("data-mirror-")) {
          return true;
        }
        logger$1.warn(`"${attrName}" will not be mirrored.`);
        return false;
      } else {
        return !attrName.startsWith("_");
      }
    };
    addEventListener(eventName, listener, options) {
      let key = this.#listenerKeyMap.get(listener);
      if (!key) {
        key = `${eventName}_${this.#listenerKeySeed++}`;
        this.#listenerKeyMap.set(listener, key);
      }
      if (this.#loIFrame.iframeReady) {
        super.addEventListener(...arguments);
        this.#loIFrame.postMessage({
          name: eventName,
          options,
          listenerKey: key,
          type: messages.lo.addEventListener
        });
      } else {
        this.#eventQueue.push({ type: "add", args: [eventName, listener, options] });
        logger$1.debug(`addEventListener:`, `#eventQueue pushed add args:`, [eventName, listener, options]);
      }
    }
    dispatchEvent(event) {
      if (event.type.startsWith("lo.")) {
        logger$1.debug(`dispatchEvent: dispatching event "${event.type}" to this Element only`);
        return super.dispatchEvent(event);
      } else {
        if (this.#loIFrame.iframeReady) {
          logger$1.debug(`dispatchEvent: dispatching event "${event.type}" to this Element and embedded Element inside the iframe`);
          const result = super.dispatchEvent(event);
          this.#loIFrame.postMessage({
            name: event.type,
            detail: event.detail || {},
            type: messages.lo.dispatchEvent
          });
          return result;
        } else {
          logger$1.debug(`dispatchEvent: iframe not reade, queueing event "${event.type}"`);
          this.#eventQueue.push({ type: "dispatch", event });
          return true;
        }
      }
    }
    removeEventListener(eventName, listener, options) {
      const key = this.#listenerKeyMap.get(listener);
      if (this.#loIFrame.iframeReady) {
        super.removeEventListener(...arguments);
        this.#loIFrame.postMessage({
          name: eventName,
          options,
          listenerKey: key,
          type: messages.lo.removeEventListener
        });
      } else {
        this.#eventQueue.push({ type: "remove", args: [eventName, listener, options] });
        logger$1.debug(`removeEventListener:`, `#eventQueue pushed remove args:`, [eventName, listener, options]);
      }
      if (key) {
        this.#listenerKeyMap.delete(listener);
      }
    }
    adoptedCallback() {
      this.remove();
      throw this.#loError.create("This component cannot be rerendered for security reasons.");
    }
    connectedCallback() {
      logger$1.trace("connectedCallback: called", `_uuid: ${this._uuid}`);
      window.addEventListener("message", this.#messageListener);
      if (this.hasChildNodes()) {
        throw this.#loError.create("Should not have child nodes");
      }
      this.style.display ||= "block";
      this.style.width ||= "100%";
      this.style.height ||= "100%";
      this.#parentApp = registry.registerComponent(this);
      this._standardName = this.#parentApp._getComponentStandardName(this);
      if (this.#parentApp._ready) {
        this._init();
      }
    }
    disconnectedCallback() {
      logger$1.trace("disconnectedCallback: called", `_uuid: ${this._uuid}`);
      this.#loIFrame.destroy();
      window.removeEventListener("message", this.#messageListener);
      registry.unregisterComponent(this);
      this.#propObserver?.disconnect();
    }
    connectedMoveCallback() {
    }
  };
  var LightningOutRouter = class {
    config;
    errorHandler;
    constructor(config, errorHandler) {
      this.config = config;
      this.errorHandler = errorHandler;
    }
    getComponentURL(componentName, parentElementId) {
      if (!this.config.origin) {
        throw this.errorHandler(`Missing "frontdoor-url" or "org-url" attribute`);
      }
      const isAuth = componentName === this.config.authComp;
      let appURL;
      if (this.config.sitePrefix === void 0) {
        if (isAuth) {
          appURL = new URL(this.config.lwrAppAuth, this.config.origin);
        } else {
          let lwrApp = componentName.includes("/") ? this.config.lwrAppComp : componentName.includes(":") ? this.config.lwrAppAura : void 0;
          if (lwrApp === void 0) {
            throw this.errorHandler(`Invalid componentName: ${componentName}`);
          }
          lwrApp = lwrApp.replace("/", "%2F");
          const lang = this.config.lang ? `l/${this.config.lang}/` : "";
          appURL = new URL(`lwr/application/amd/0/${lang}ai/${lwrApp}`, this.config.origin);
        }
      } else {
        const pathname = `${this.config.sitePrefix}/lightning-out`;
        appURL = new URL(pathname, this.config.origin);
      }
      if (!isAuth) {
        appURL.searchParams.set("componentName", componentName);
      }
      appURL.searchParams.set("parentElementId", parentElementId);
      appURL.searchParams.set("loAppOrigin", this.config.loAppOrigin);
      if (this.config.appId) {
        appURL.searchParams.set("appId", this.config.appId);
      }
      if (this.config.testMode) {
        appURL.searchParams.set("testMode", "true");
      }
      return appURL;
    }
  };
  var logger = new Logger("LightningOutApplication");
  var INIT_TRIGGERING_PROPS = /* @__PURE__ */ new Set(["frontdoorUrl", "orgUrl"]);
  var AUTH_PAGE_LAST_MOD = 1762330051;
  var LightningOutApplication = class extends HTMLElement {
    _uuid = getUUID();
    _ready = false;
    #loError = new LightningOutError(this);
    #loIFrame = new LightningOutIFrame({
      parentElement: this,
      isVisible: false
    });
    #loRouter;
    #propObserver;
    #lwrAppOrigin = "";
    #lwrAppComp = "lightningout/container";
    #lwrAppAura = "lightningout/auraContainer";
    #lwrAppAuth = "lightning/lightning.out.auth.html";
    #authComp = "lo2auth";
    #logoutUrl = "/secur/logout.jsp";
    lwrApplication;
    orgUrl;
    #orgUrl;
    frontdoorUrl;
    #frontdoorUrl;
    appId;
    #appId;
    components;
    // CSV of component names
    #compNames = /* @__PURE__ */ new Map();
    // a Map of of component name->alias
    sitePrefix;
    #sitePrefix;
    constructor() {
      super();
      logger.trace("constructor: called", `_uuid: ${this._uuid}`);
      registry.registerApplication(this);
    }
    #access(orgUrl) {
      try {
        this.#orgUrl = new URL(orgUrl);
      } catch {
        throw this.#loError.create(`Invalid org-url: ${orgUrl}`);
      }
      this.dispatchEvent(new CustomEvent(events.lo.iframe.load, {
        detail: this.#orgUrl.origin
      }));
    }
    #login(frontdoorUrl) {
      try {
        this.#frontdoorUrl = new URL(frontdoorUrl);
        this.#lwrAppOrigin = this.#frontdoorUrl.origin;
        const startURL = this.getAuthComponentURL();
        const paramName = this.#frontdoorUrl.searchParams.has("otp") ? "startURL" : "retURL";
        this.#frontdoorUrl.searchParams.set(paramName, startURL.pathname + startURL.search);
      } catch {
        throw this.#loError.create(`Invalid frontdoor-url: ${frontdoorUrl}`);
      }
      this.#loIFrame.load(this.#frontdoorUrl.href);
    }
    #logout() {
      const logoutUrl = new URL(this.#logoutUrl, this.#lwrAppOrigin);
      this.#loIFrame.load(logoutUrl.href);
      setTimeout(() => {
        this.dispatchEvent(new CustomEvent(events.lo.application.logout));
      }, 3e3);
    }
    getRouter() {
      if (this.#loRouter === void 0) {
        const config = {
          origin: this.#lwrAppOrigin,
          lwrAppComp: this.#lwrAppComp,
          lwrAppAura: this.#lwrAppAura,
          lwrAppAuth: this.#lwrAppAuth,
          authComp: this.#authComp,
          sitePrefix: this.#sitePrefix,
          lang: this.lang,
          appId: this.#appId,
          testMode: this.__testMode || false,
          loAppOrigin: window.location.origin
        };
        this.#loRouter = new LightningOutRouter(config, (msg) => this.#loError.create(msg));
      }
      return this.#loRouter;
    }
    getComponentURL(componentName, parentElementId) {
      return this.getRouter().getComponentURL(componentName, parentElementId);
    }
    getAuthComponentURL() {
      const authCompURL = this.getComponentURL(this.#authComp, this._uuid);
      authCompURL.searchParams.set("lo_auth_page_last_mod", AUTH_PAGE_LAST_MOD.toString());
      return authCompURL;
    }
    #iframeLoaded = (event) => {
      this._ready = true;
      this.#lwrAppOrigin = event.detail;
      this.#initComponents();
      this.dispatchEvent(new CustomEvent(events.lo.application.ready));
    };
    #iframeError = (event) => {
      this.#loError.dispatch(events.lo.application.error, event);
    };
    #initComponents() {
      const myComps = registry.getComps(this);
      myComps.forEach((comp) => {
        comp._init();
      });
    }
    #propObserverCallback = (changes) => {
      const changesFirst = {};
      const changesLast = {};
      Object.keys(changes).forEach((prop) => {
        if (INIT_TRIGGERING_PROPS.has(prop)) {
          changesLast[prop] = changes[prop];
        } else {
          changesFirst[prop] = changes[prop];
        }
      });
      processPropertyChanges(this, changesFirst);
      processPropertyChanges(this, changesLast);
    };
    #shouldObserveCallback = (propName, isStandard) => {
      if (isStandard) {
        return false;
      } else {
        return !propName.startsWith("_");
      }
    };
    _propertyChanged_lwrApplication = (lwrApplication) => {
      if (lwrApplication !== void 0) {
        const parts = lwrApplication.split("/");
        if (parts.length !== 2 || !parts[0] || !parts[1]) {
          throw this.#loError.create(`"${lwrApplication}" is not a valid lwr-application name, must be of the form 'namespace/name'`);
        }
        this.#lwrAppComp = lwrApplication;
      }
    };
    _propertyChanged_orgUrl = (orgUrl) => {
      if (orgUrl !== void 0) {
        if (this.#frontdoorUrl !== void 0) {
          throw this.#loError.create(`Can't set "org-url" because "frontdoor-url" is already set`);
        }
        this.#access(orgUrl);
      }
    };
    _propertyChanged_frontdoorUrl = (frontdoorUrl) => {
      if (frontdoorUrl !== void 0) {
        if (this.#orgUrl !== void 0) {
          throw this.#loError.create(`Can't set "frontdoor-url" because "org-url" is already set`);
        }
        if (frontdoorUrl === "") {
          this.#logout();
        } else {
          this.#login(frontdoorUrl);
        }
      }
    };
    _propertyChanged_sitePrefix = (sitePrefix) => {
      if (sitePrefix !== void 0) {
        this.#sitePrefix = sitePrefix;
      }
    };
    _propertyChanged_appId = (appId) => {
      if (appId !== void 0) {
        this.#appId = appId;
      }
    };
    /**
     * components is a comma separated list of names with optional aliases. The names can be standard (i.e. foo/bar) or
     * kebab (i.e. foo-bar). It is recommended to use standard names because that's what the backend runtime requires,
     * and converting from kebab name to standard name can be ambiguous. (W-19562914)
     *
     * Example: components = "foo/bar, baz-qux, c/myComp as alias-for-my-comp, other-comp as other-comp-alias"
     */
    _propertyChanged_components = (components) => {
      if (components === void 0) {
        return;
      }
      components.split(",").forEach((comp) => {
        const [name, alias] = comp.split(" as ").map((n) => n.trim());
        const isStandard = isStandardName(name);
        if (isStandard && name.includes(":")) {
          throw this.#loError.create(`"${name}" is not supported in components. Use  kebab "namespace-name" in components and the "aura" attribute on the component element instead.`);
        }
        const standardName = isStandard ? name : elementNameToStandardName(name);
        const localName = alias || (isStandard ? standardNameToElementName(standardName) : name);
        if (localName && !this.#compNames.has(localName)) {
          this.#compNames.set(localName, standardName);
          try {
            registry.registerComponentName(localName, this);
            customElements.define(localName, class extends LightningOutComponent {
            });
          } catch (err) {
            throw this.#loError.create(`"${localName}" is already registered. ${err}`);
          }
        }
      });
    };
    _getComponentStandardName(component) {
      const localName = component.localName;
      const isAura = component.hasAttribute("aura");
      const standardName = this.#compNames.get(localName);
      if (!standardName) {
        throw this.#loError.create(`"${localName}" is not registered.`);
      }
      if (isAura && standardName.includes("/")) {
        return standardName.replace("/", ":");
      }
      return standardName;
    }
    get _compNames() {
    }
    connectedCallback() {
      logger.trace("connectedCallback: called", `_uuid: ${this._uuid}`);
      if (this.hasChildNodes()) {
        throw this.#loError.create("Should not have child nodes");
      }
      this.style.display ||= "none";
      this.addEventListener(events.lo.iframe.load, this.#iframeLoaded);
      this.addEventListener(events.lo.iframe.error, this.#iframeError);
      this.#propObserver = new PropertyObserver(this, this.#propObserverCallback, this.#shouldObserveCallback);
    }
    disconnectedCallback() {
      logger.trace("disconnectedCallback: called", `_uuid: ${this._uuid}`);
      this.#logout();
      this.#loIFrame.destroy();
      this.removeEventListener(events.lo.iframe.load, this.#iframeLoaded);
      this.removeEventListener(events.lo.iframe.error, this.#iframeError);
      this.#propObserver?.disconnect();
    }
    connectedMoveCallback() {
    }
  };
  Logger.level = "debug";
  window.customElements.define("lightning-out-application", LightningOutApplication);

  // node_modules/@salesforce/agentforce-conversation-client/dist/index.js
  var AGENTFORCE_CLIENT_ELEMENT_TAG = "runtime_copilot-acc-sdk-wrapper";
  var AGENTFORCE_CLIENT_NAMESPACE = "runtime_copilot";
  var AGENTFORCE_CLIENT_COMPONENT_NAME = "accSdkWrapper";
  var AGENTFORCE_LO_APP_DATA_ATTR = "data-lo";
  var RenderingMode = Object.freeze({
    INLINE: "inline",
    FLOATING: "floating"
  });
  var EVENTS = Object.freeze({
    ACC_MAXIMIZE: "accmaximize",
    ACC_MINIMIZE: "accminimize",
    ACC_READY: "accready"
  });
  var STYLE_ID = "agentforce-client-injected-styles";
  var FLOATING_DIMENSIONS = Object.freeze({
    MINIMIZED_HEIGHT: "56px",
    MAXIMIZED_HEIGHT: "742px"
  });
  var AGENTFORCE_CLIENT_CSS = `
:root {
    --minimized-iframe-width: 180px !important;
    --minimized-iframe-height: 70px !important;
}

.acc-container:has(> .acc-frame.inline) {
    height: 100%;
    width: 100%;
}

.sds-overrides {
  width: auto;
}

.acc-container > .acc-frame {
    display: block;
    position: fixed;
    background: transparent;
    border: none;
    outline: none;
    border-radius: 20px;
    bottom: 24px;
    right: 24px;
    height: 0 !important;
    width: 0 !important;
    max-width: calc(100vw - 4rem);
    max-height: calc(100dvh - 4rem);
    z-index: 999;
}

.acc-container > .acc-frame.inline,
.acc-container > .acc-frame.inline.maximize {
    height: 100% !important;
    width: 100% !important;
    position: static;
    bottom: 0;
    right: 0;
    max-height: 100%;
    max-width: 100%;
    box-shadow: none;
    border-radius: 0;
}

.acc-container > .acc-frame.inline:not(.maximize) {
    width: var(--acc-width, auto) !important;
    height: var(--acc-height, auto) !important;
}

.acc-container > .acc-frame.initial {
    height: var(--minimized-iframe-height, 56px) !important;
    width: var(--minimized-iframe-width, 145px) !important;
    transition: all 0s ease;
}

.acc-container > .acc-frame.minimize {
    height: var(--minimized-iframe-height, 56px) !important;
    width: var(--minimized-iframe-width, 145px) !important;
    transition: width 0.25s ease-in-out, height 0.25s ease-in-out;
}

.acc-container > .acc-frame.maximize {
    width: 450px !important;
    height: 700px !important;
    background: #ffffff;
    box-shadow: 0 10px 25px -3px rgba(0, 0, 0, 0.1), 0 4px 12px -2px rgba(0, 0, 0, 0.05),
        0 0 2px 0 rgba(0, 0, 0, 0.05), 0 20px 45px -5px rgba(0, 0, 0, 0.08);
    transition: all 0.3s ease;
}

.acc-container > lightning-out-application {
    background: transparent;
}

@media (max-width: 639px) {
    .acc-container > .acc-frame.maximize {
        bottom: 0;
        right: 0;
        width: 100% !important;
        height: 100vh !important;
        height: 100dvh !important;
        border-radius: 0;
        max-width: 100%;
        max-height: 100vh;
        overflow-y: auto;
        overflow-x: hidden;
        -webkit-overflow-scrolling: touch;
        transition: height 0.2s ease-in-out;
    }
}
`;
  function injectStyles(additionalCss = "") {
    if (document.getElementById(STYLE_ID))
      return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = AGENTFORCE_CLIENT_CSS + (additionalCss ? "\n" + additionalCss : "");
    document.head.appendChild(style);
  }
  function toCssLength(value) {
    return typeof value === "number" ? `${value}px` : value;
  }
  function normalizeRenderingMode(value) {
    if (value === RenderingMode.INLINE || value === RenderingMode.FLOATING)
      return value;
    return void 0;
  }
  function getRenderingContext(clientConfig) {
    const renderingConfig = clientConfig?.renderingConfig ?? {};
    const mode = normalizeRenderingMode(renderingConfig.mode) ?? RenderingMode.FLOATING;
    const isFloating = mode !== RenderingMode.INLINE;
    return { mode, isFloating, renderingConfig };
  }
  function applyInlineSizing(container, { width, height }) {
    if (width != null)
      container.style.setProperty("--acc-width", toCssLength(width));
    if (height != null) {
      const h = toCssLength(height);
      container.style.setProperty("--acc-height", h);
      container.style.setProperty("--agentic-chat-container-height", h);
    }
  }
  function createFrameElement() {
    const el = document.createElement(AGENTFORCE_CLIENT_ELEMENT_TAG);
    el.classList.add("acc-frame");
    return el;
  }
  function applyFrameInitialState(el, context, container) {
    el.style.opacity = "0";
    el.style.pointerEvents = "none";
    el.style.setProperty("--agentic-chat-container-height", "100vh");
    if (context.isFloating) {
      el.classList.add("floating");
      el.classList.remove("maximize", "minimize");
      el.classList.add("initial");
    } else {
      el.classList.add("inline");
      applyInlineSizing(container, context.renderingConfig);
    }
  }
  function attachFrameResizeHandlers(el, container, isFloating, loApp) {
    const onAccReady = () => {
      el.style.opacity = "";
      el.style.pointerEvents = "";
      if (loApp) {
        loApp.style.opacity = "";
        loApp.style.pointerEvents = "";
      }
    };
    el.addEventListener(EVENTS.ACC_READY, onAccReady);
    if (!isFloating)
      return;
    const onMaximize = () => {
      el.classList.remove("initial", "minimize");
      el.classList.add("maximize");
    };
    const onMinimize = () => {
      el.classList.remove("maximize");
      el.classList.add("minimize");
      container.style.setProperty("--agentic-chat-container-height", FLOATING_DIMENSIONS.MINIMIZED_HEIGHT);
    };
    el.addEventListener(EVENTS.ACC_MAXIMIZE, onMaximize);
    el.addEventListener(EVENTS.ACC_MINIMIZE, onMinimize);
  }
  function createAndMountFrame(container, clientConfig, loApp) {
    injectStyles();
    const config = { ...clientConfig ?? {} };
    const context = getRenderingContext(config);
    const el = createFrameElement();
    el.configuration = config;
    applyFrameInitialState(el, context, container);
    attachFrameResizeHandlers(el, container, context.isFloating, loApp);
    container.appendChild(el);
    return el;
  }
  function createAndMountLoApp(container, salesforceOrigin, appId, frontdoorUrl) {
    const loApp = new LightningOutApplication();
    if (salesforceOrigin)
      loApp.setAttribute("org-url", salesforceOrigin);
    loApp.setAttribute("components", `${AGENTFORCE_CLIENT_NAMESPACE}/${AGENTFORCE_CLIENT_COMPONENT_NAME}`);
    loApp.setAttribute(AGENTFORCE_LO_APP_DATA_ATTR, `acc`);
    if (appId)
      loApp.setAttribute("app-id", appId);
    if (frontdoorUrl)
      loApp.setAttribute("frontdoor-url", frontdoorUrl);
    loApp.style.opacity = "0";
    loApp.style.pointerEvents = "none";
    attachLoEventHandlers(loApp);
    container.appendChild(loApp);
    return loApp;
  }
  function attachLoEventHandlers(loApp) {
    loApp.addEventListener("lo.application.ready", (e) => {
      console.log("Agentforce Conversation Client: Lightning Out ready", e.detail != null ? e.detail : "");
    });
    loApp.addEventListener("lo.application.error", (e) => {
      console.error("Agentforce Conversation Client: Lightning Out error:", e.detail);
    });
    loApp.addEventListener("lo.iframe.error", (e) => {
      console.error("Agentforce Conversation Client: Lightning Out iframe error:", e.detail);
    });
  }
  function resolveContainer(container) {
    if (container instanceof HTMLElement)
      return container;
    if (typeof container === "string")
      return document.querySelector(container);
    return null;
  }
  function embedIntoContainer(containerElement, options) {
    const { salesforceOrigin, appId, frontdoorUrl, agentforceClientConfig = {} } = options;
    containerElement.classList.add("acc-container");
    const loApp = createAndMountLoApp(containerElement, salesforceOrigin, appId, frontdoorUrl);
    const chatClientComponent = createAndMountFrame(containerElement, agentforceClientConfig, loApp);
    return { loApp, chatClientComponent };
  }
  function embedAgentforceClient(options) {
    const { container, salesforceOrigin, appId, frontdoorUrl, agentforceClientConfig = {} } = options ?? {};
    if (!container)
      throw new Error("Agentforce Conversation Client: container is required");
    if (!salesforceOrigin && !frontdoorUrl) {
      throw new Error("Agentforce Conversation Client: salesforceOrigin or frontdoorUrl is required");
    }
    const containerElement = resolveContainer(container);
    if (!containerElement) {
      throw new Error(`Agentforce Conversation Client: container not found: ${container}`);
    }
    return embedIntoContainer(containerElement, {
      container,
      salesforceOrigin,
      appId,
      frontdoorUrl,
      agentforceClientConfig
    });
  }

  // entry.js
  window.embedAgentforceClient = embedAgentforceClient;
  window.__AGENTFORCE_CONVERSATION_CLIENT_STUB__ = false;
})();
