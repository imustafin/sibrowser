import { Controller } from '@hotwired/stimulus';
import StoredArray from 'stored_array';

export default class extends Controller {
  static targets = [
    'checkbox'
  ]

  key = 'sibrowser:bookmarks';

  initialize() {
    this.bookmarks = new StoredArray(this.key);
  }

  connect() {
    window.addEventListener('storage', this.storageListener);
  }

  disconnect() {
    window.removeEventListener('storage', this.storageListener);
  }

  // bound listener to remove when needed
  storageListener = ({ key, newValue }) => {
    if (key !== this.key) {
      return;
    }

    const set = new Set(this.bookmarks.parse(newValue));

    this.checkboxTargets.forEach(el => {
      el.checked = set.has(this.id(el));
    });
  }

  id(el) {
    return parseInt(el.dataset.id);
  }


  checkboxTargetConnected(el) {
    el.checked = this.bookmarks.has(this.id(el));
  }

  switch({ currentTarget }) {
    const id = this.id(currentTarget);
    const checkbox = currentTarget.querySelector(`[data-id="${id}"]`);

    if (checkbox.checked) {
      this.bookmarks.remove(id);
      checkbox.checked = false;
    } else {
      this.bookmarks.add(id);
      checkbox.checked = true;
    }
  }
};
