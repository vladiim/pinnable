# Single self-contained entrypoint. It imports only "@hotwired/stimulus" (which the
# host already pins), so there are no further pins to resolve.
pin "pinnable", to: "pinnable.js", preload: true
