import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "pagination",
    "afterLast",
    "beforeFloating",
    "firstBeforeFirst",
  ]

  initialize() {
    this.observer = new IntersectionObserver(es => this.handleIntersect(es), {
      threshold: [0, 1],
    });
  }

  connect() {
    this.observer.observe(this.afterLastTarget);
    this.observer.observe(this.beforeFloatingTarget);
    this.observer.observe(this.firstBeforeFirstTarget);
  }

  registerBeforeFirst(element) {
    this.observer.observe(element);
  }

  handleIntersect(entries) {
    let minPageStart = Number.MAX_SAFE_INTEGER;

    entries.forEach(entry => {
      if (entry.target === this.afterLastTarget) {
        this.afterLastIntersects(entry);
      }
      if (entry.target === this.beforeFloatingTarget) {
        this.beforeFloatingIntersects(entry);
      }

      if (entry.isIntersecting
          && entry.target.dataset.pageNumber) {
        const page = parseInt(entry.target.dataset.pageNumber);
        minPageStart = Math.min(minPageStart, page);
      }
    });

    if (minPageStart !== Number.MAX_SAFE_INTEGER) {
      this.updatePagination(minPageStart);
    }
  }

  updatePagination(page) {
    const url = new URL(window.location);
    url.searchParams.set('page', page);
    url.searchParams.set('only_pagination', true);

    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
      }
    })
      .then(r => r.text())
      .then(html => Turbo.renderStreamMessage(html))
  }

  afterLastIntersects(intersection) {
    const isIntersecting = intersection.isIntersecting;
    const afterLast = this.afterLastTarget;

    if (isIntersecting) {
      const next = this.paginationTarget.querySelector('[rel=next]');
      if (!next) {
        afterLast.classList.toggle('hidden', true); // don't come here ever again
        return;
      }

      afterLast.classList.toggle('invisible', false);

      const url = new URL(next.href);
      url.searchParams.delete('only_pagination');
      fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
        }
      })
        .then(r => r.text())
        .then(html => Turbo.renderStreamMessage(html))
        .then(_ => afterLast.classList.toggle('invisible', true));
    }
  }

  beforeFloatingIntersects(intersection) {
    const isIntersecting = intersection.isIntersecting;
    this.paginationTarget.classList.toggle('bg-white', !isIntersecting);
  }
}
