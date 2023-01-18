import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['table'];

  setWholeTheme({ target, params }) {
    let { round, theme, ans } = params;

    let table = this.tableTarget;
    let radios = table.querySelectorAll(
      `input[id^="${round}_${theme}_"][id$="${ans}"][type="radio"]`
    );
    radios.forEach(radio => radio.checked = true);
  }

  setThemeCat({ target, params }) {
    let { round, theme, ans, cat, only } = params;

    let table = this.tableTarget;

    if (only) {
      table.querySelectorAll(`input[id^="${round}_${theme}_"][id$="no"][type="radio"]`)
        .forEach(radio => radio.checked = true);
    }

    let radios = table.querySelectorAll(
      `input[id^="${round}_${theme}_"][id$="${cat}_${ans}"][type="radio"]`
    );
    radios.forEach(radio => radio.checked = true);
  }
}
