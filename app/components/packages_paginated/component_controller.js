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

  }

  beforeFloatingIntersects(intersection) {
    const inter = intersection.isIntersecting;
    this.paginationTarget.classList.toggle('bg-white', !inter);
  }
}
