import { Controller } from '@hotwired/stimulus';
import StoredArray from 'stored_array';

export default class extends Controller {
  static targets = [
    'empty',
    'afterLast',
    'package'
  ]


  // same as SibrowserConfig::LOCAL_PAGINATION_SIZE
  LOCAL_PAGINATION_SIZE = 5;

  initialize() {
    this.observer = new IntersectionObserver(es => this.handleIntersect(es), {
      threshold: [0, 1],
    });

    this.loadingContents = false;
    this.dataset = new StoredArray(this.element.dataset.localkey);
  }

  connect() {
    this.observer.observe(this.afterLastTarget);

    if (this.dataset.getAll().length === 0) {
      this.showEmpty();
    }

    this.triedIds = new Set();
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.target === this.afterLastTarget) {
        this.afterLastIntersects(entry);
      }
    });
  }

  showEmpty() {
    this.emptyTarget.classList.toggle('hidden', false);
    this.afterLastTarget.classList.toggle('hidden', true);
  }

  async afterLastIntersects(intersection) {
    const isIntersecting = intersection.isIntersecting;

    if (this.loadingContents) {
      return; // don't load two things at once
    }

    if (isIntersecting) {
      this.fetchMore(this.LOCAL_PAGINATION_SIZE);
    }
  }

  async fetchMore(count) {
    const afterLast = this.afterLastTarget;

    const nextPageIds = this.getNextPageIds(count);

    if (nextPageIds.length === 0) {
      // no more unloaded packages, don't come here ever again
      afterLast.classList.toggle('hidden', true);
      if (!this.hasPackageTarget) {
        this.showEmpty();
      }
      return;
    }

    const url = '/profile/bookmarks?' + nextPageIds.map(x => `ids[]=${x}`).join('&');

    afterLast.classList.toggle('invisible', false);
    this.loadingContents = true;
    nextPageIds.forEach(id => this.triedIds.add(id));
    try {
      const result = await fetch(url, {
        headers: {
          Accept: 'text/vnd.turbo-stream.html',
        }
      });
      if (!result.ok) {
        throw new Error(`Response not ok ${result}`);
      }

      const foundCount = parseInt(result.headers.get('SIB_FOUND_COUNT'));
      const html = await result.text();
      Turbo.renderStreamMessage(html);
      if (foundCount < nextPageIds.length) {
        await this.fetchMore(count - foundCount);
      } else {
        afterLast.classList.toggle('invisible', true);
      }
    } catch(e) {
      console.error(e);
    } finally {
      this.loadingContents = false;
    }
  }

  getNextPageIds(count) {
    const ar = this.dataset.getAll();
    const present = this.triedIds;

    const next = [];

    for (var i = 0; i < ar.length; i++) {
      if (!present.has(ar[i])) {
        next.push(ar[i]);
        if (next.length === count) {
          break;
        }
      }
    }

    return next;
  }
}
