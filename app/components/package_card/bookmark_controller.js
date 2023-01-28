import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'checkbox'
  ]

  key = 'sibrowser:bookmarks';

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

    const set = new Set(this.parse(newValue));

    this.checkboxTargets.forEach(el => {
      el.checked = set.has(this.id(el));
    });
  }

  id(el) {
    return parseInt(el.dataset.id);
  }

  // parse data from local storage, return [] as fallback
  parse(s) {
    if (!s) {
      return [];
    }

    try {
      const parsed = JSON.parse(s);
      if (Array.isArray(parsed)) {
        return parsed;
      }
      return [];
    } catch(e) {
      if (e instanceof SyntaxError) {
        // Probably corrupt string
        return [];
      } else {
        throw e;
      }
    }
  }

  get() {
    return this.parse(window.localStorage.getItem(this.key));
  }

  set(id) {
    const ar = this.get();

    if (!ar.includes(id)) {
      ar.push(id);
      window.localStorage.setItem(this.key, JSON.stringify(ar));
    }
  }

  unset(id) {
    const newAr = this.get().filter(x => x != id);

    if (newAr.length > 0) {
      window.localStorage.setItem(this.key, JSON.stringify(newAr));
    } else {
      window.localStorage.removeItem(this.key);
    }
  }

  checkboxTargetConnected(el) {
    el.checked = this.get().includes(this.id(el));
  }

  switch() {
    const id = this.id(this.checkboxTarget);

    if (this.checkboxTarget.checked) {
      this.unset(id);
      this.checkboxTarget.checked = false;
    } else {
      this.set(id);
      this.checkboxTarget.checked = true;
    }
  }
};
