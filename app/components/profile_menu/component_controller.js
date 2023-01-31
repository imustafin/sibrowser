import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'wrapper',
    'checkbox',
    'menu'
  ]

  disable = () => {
    console.log('disable');
    window.removeEventListener('click', this.disable);
    this.checkboxTarget.checked = false;
  }

  enable = () => {
    console.log('enable');
    window.addEventListener('click', this.disable);
    this.checkboxTarget.checked = true;
  }

  toggle() {
    const active = this.checkboxTarget.checked;

    if (active) {
      this.disable();
    } else {
      this.enable();
    }
  }
}
