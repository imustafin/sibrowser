export default class {
  constructor(key) {
    this.key = key;
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

  getAll() {
    return this.parse(window.localStorage.getItem(this.key));
  }

  add(id) {
    const ar = this.getAll();

    if (!ar.includes(id)) {
      ar.unshift(id);
      window.localStorage.setItem(this.key, JSON.stringify(ar));
    }
  }

  remove(id) {
    const newAr = this.getAll().filter(x => x != id);

    if (newAr.length > 0) {
      window.localStorage.setItem(this.key, JSON.stringify(newAr));
    } else {
      window.localStorage.removeItem(this.key);
    }
  }

  has(id) {
    return this.getAll().includes(id);
  }
}
