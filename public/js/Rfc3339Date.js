class Rfc3339Date extends HTMLElement {
  constructor() {
    super();
    const shadowRoot = this.attachShadow({ mode: 'open' });
    shadowRoot.innerHTML = `
<style>
div {
  position: relative;
  width: 20px;
  height: 20px;
}

input[type="date"] {
  color: transparent;
  background-color: transparent;
  position: absolute;
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
  color: transparent;
  background-color: transparent;
  width: 20px;
  height: 20px;
  padding: 0;
}

label::after {
  display: inline-block;
  content: '';
  position: absolute;
  width: 20px;
  height: 20px;
  background: url(image/calendar.png);
  background-size: 20px 20px;
  background-repeat: no-repeat;
}
</style>
<div>
 <label></label><input type="date">
</div>
`;
    const $input = shadowRoot.querySelector('input');
    $input.addEventListener('change', event => {
      const $elm = event.currentTarget;
      const rfc3339String = $elm.value ? `${$elm.value}T00:00:00.000Z` : '';
      this.dispatchEvent(
        new CustomEvent('dateChange', {
          detail: {
            rfc3339: rfc3339String,
            key: 1
          }
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
        const parseDate = new Date(Date.parse(newVal));
        const date = `${parseDate.getFullYear()}-${zeroPadding(
          parseDate.getMonth() + 1,
          2
        )}-${zeroPadding(parseDate.getDate(), 2)}`;
        this.shadowRoot.querySelector('input[type=date]').value = date;
        break;
    }
  }
}

function zeroPadding(num, length) {
  return ('0000000000' + num).slice(-length);
}

customElements.define('rfc3339-date', Rfc3339Date);
