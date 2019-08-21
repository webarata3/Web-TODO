class Rfc3339Date extends HTMLElement {
  constructor() {
    super();
    const shadowRoot = this.attachShadow({ mode: 'open' });
    shadowRoot.innerHTML = `
<style>
:host {
  --component-size: 1rem;
}

span {
  position: relative;
  height: var(--component-size);
  display: inline-flex;
  align-items: center;
}

input[type="date"] {
  color: transparent;
  background-color: transparent;
  position: absolute;
  right: 0;
  padding: 0;
  outline: none;
  border: none;
}

input[type="date"]::-webkit-inner-spin-button{
  -webkit-appearance: none;
  display: none;
}

input[type="date"]::-webkit-clear-button{
  -webkit-appearance: none;
  display: none;
}

input[type="date"]::-webkit-datetime-edit {
  display: none;
}

input[type="date"]::-webkit-calendar-picker-indicator,
input[type="date"]::-webkit-calendar-picker-indicator:hover {
  cursor: pointer;
  color: transparent;
  background-color: transparent;
  width: var(--component-size);
  height: var(--component-size);
  padding: 0;
}

label {
  display: inline-flex;
  align-items: center;
  font-size: var(--component-size);
  height: var(--component-size);
}

label::after {
  display: inline-block;
  content: '';
  width: var(--component-size);
  height: var(--component-size);
  background: url(image/calendar.png);
  background-size: var(--component-size) var(--component-size);
  background-repeat: no-repeat;
  background-position: right;
}

label.selected::after {
  width: calc(var(--component-size) + 0.3rem);
}
</style>
<span>
 <label></label><input type="date">
</span>
`;
    const $input = shadowRoot.querySelector('input');
    $input.addEventListener('change', event => {
      const $elm = event.currentTarget;
      const rfc3339String = $elm.value ? `${$elm.value}T00:00:00.000Z` : '';
      this.setNewDate($elm.value);
      this.dispatchEvent(
        new CustomEvent('dateChange', {
          detail: rfc3339String
        })
      );
    });
    shadowRoot.querySelector('label').addEventListener('click', () => {
      $input.focus();
    });
  }

  static get observedAttributes() {
    return ['rfc3339'];
  }

  attributeChangedCallback(attrName, oldVal, newVal) {
    switch (attrName) {
      case 'rfc3339':
        this.setNewDate(newVal);
        break;
    }
  }

  setNewDate(newVal) {
    const checkDate = Date.parse(newVal);
    const $label = this.shadowRoot.querySelector('label');
    if (isNaN(checkDate)) {
      $label.textContent = '';
      $label.classList.remove('selected');
    } else {
      const parseDate = new Date(checkDate);
      const date = `${parseDate.getFullYear()}-${zeroPadding(
        parseDate.getMonth() + 1,
        2
      )}-${zeroPadding(parseDate.getDate(), 2)}`;
      this.shadowRoot.querySelector('input[type=date]').value = date;
      $label.classList.add('selected');
      $label.textContent = `${parseDate.getFullYear()}-${zeroPadding(
        parseDate.getMonth() + 1,
        2
      )}-${zeroPadding(parseDate.getDate(), 2)}`;
    }
  }
}

function zeroPadding(num, length) {
  return ('0000000000' + num).slice(-length);
}

customElements.define('rfc3339-date', Rfc3339Date);
