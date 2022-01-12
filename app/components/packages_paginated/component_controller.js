import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "pagination",
    "afterLast",
    "beforeFloating",
  ]

  connect() {
    this.createObserver();
  }

  createObserver() {
    const observer = new IntersectionObserver(es => this.handleIntersect(es), {
      threshold: [0, 1],
    });

    observer.observe(this.afterLastTarget);
    observer.observe(this.beforeFloatingTarget);
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.target === this.afterLastTarget) {
        this.afterLastIntersects(entry);
      }
      if (entry.target === this.beforeFloatingTarget) {
        this.beforeFloatingIntersects(entry);
      }
    });
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

      const href = next.href;
      fetch(href, {
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
