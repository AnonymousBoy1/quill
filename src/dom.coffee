_     = require('lodash')
_.str = require('underscore.string')

lastKeyEvent = null    # Workaround for fact we can't dispatch keyboard event via javascript

DOM =
  ELEMENT_NODE: 1
  NOBREAK_SPACE:  "&nbsp;"
  TEXT_NODE: 3
  ZERO_WIDTH_NOBREAK_SPACE:  "\uFEFF"

  DEFAULT_BLOCK_TAG: 'DIV'
  DEFAULT_BREAK_TAG: 'BR'
  DEFAULT_INLNE_TAG: 'SPAN'

  KEYS:
    BACKSPACE : 8
    TAB       : 9
    ENTER     : 13
    ESCAPE    : 27
    LEFT      : 37
    UP        : 38
    RIGHT     : 39
    DOWN      : 40
    DELETE    : 46

  BLOCK_TAGS: {
    'ADDRESS'
    'ARTICLE'
    'ASIDE'
    'AUDIO'
    'BLOCKQUOTE'
    'CANVAS'
    'DD'
    'DIV'
    'DL'
    'FIGCAPTION'
    'FIGURE'
    'FOOTER'
    'FORM'
    'H1', 'H2', 'H3', 'H4', 'H5', 'H6'
    'HEADER'
    'HGROUP'
    'LI'
    'OL'
    'OUTPUT'
    'P'
    'PRE'
    'SECTION'
    'TABLE'
    'TBODY'
    'TD'
    'TFOOT'
    'TH'
    'THEAD'
    'TR'
    'UL'
    'VIDEO'
  }

  EMBED_TAGS: {
    'IMG'
  }

  VOID_TAGS: {
    'AREA'
    'BASE'
    'BR'
    'COL'
    'COMMAND'
    'EMBED'
    'HR'
    'IMG'
    'INPUT'
    'KEYGEN'
    'LINK'
    'META'
    'PARAM'
    'SOURCE'
    'TRACK'
    'WBR'
  }

  addClass: (node, cssClass) ->
    return if DOM.hasClass(node, cssClass)
    if node.classList?
      node.classList.add(cssClass)
    else if node.className?
      node.className = _.str.trim(node.className + ' ' + cssClass)

  addEventListener: (node, eventName, listener) ->
    node.addEventListener(eventName, (event) ->
      arg = if lastKeyEvent and (eventName == 'keydown' or eventName == 'keyup') then lastKeyEvent else event
      console.log eventName, arg
      propogate = listener(arg)
      unless propogate
        event.preventDefault()
        event.stopPropagation()
      return propogate
    )

  clearAttributes: (node, exception = []) ->
    exception = [exception] if _.isString(exception)
    _.each(DOM.getAttributes(node), (value, name) ->
      node.removeAttribute(name) unless _.indexOf(exception, name) > -1
    )

  getAttributes: (node) ->
    return {} unless node.attributes?
    attributes = {}
    for value,i in node.attributes
      attr = node.attributes[i]
      attributes[attr.name] = attr.value
    return attributes

  getChildNodes: (parent) ->
    return _.map(parent.childNodes)

  getChildren: (parent) ->
    return _.map(parent.children)

  getDescendants: (parent) ->
    return _.map(parent.getElementsByTagName('*'))

  getClasses: (node) ->
    return node.className.split(/\s+/)

  getDefaultOption: (select) ->
    return select.querySelector('option[selected]')

  getSelectValue: (select) ->
    return if select.selectedIndex > -1 then select.options[select.selectedIndex].value else ''

  getStyles: (node) ->
    styleString = node.getAttribute('style') or ''
    obj = _.reduce(styleString.split(';'), (styles, str) ->
      [name, value] = str.split(':')
      if name and value
        name = _.str.trim(name)
        value = _.str.trim(value)
        styles[name.toLowerCase()] = value
      return styles
    , {})
    return obj

  getText: (node) ->
    switch node.nodeType
      when DOM.ELEMENT_NODE
        return "" if node.tagName == DOM.DEFAULT_BREAK_TAG
        return node.textContent if node.textContent?
        return node.innerText.replace(/[\r\n]/g, '') if node.innerText?
        return ""
      when DOM.TEXT_NODE then return node.data or ""
      else return ""

  getTextNodes: (parent) ->
    results = []
    results.push(parent) if DOM.isTextNode(parent)
    _.each(DOM.getChildNodes(parent), (node) ->
      results = results.concat(DOM.getTextNodes(node))
    )
    return results

  getWindow: (node) ->
    return node.ownerDocument.defaultView or node.ownerDocument.parentWindow

  hasClass: (node, cssClass) ->
    if node.classList?
      return node.classList.contains(cssClass)
    else if node.className?
      return _.indexOf(DOM.getClasses(node), cssClass) > -1
    return false

  isElement: (node) ->
    return node?.nodeType == DOM.ELEMENT_NODE

  isTextNode: (node) ->
    return node?.nodeType == DOM.TEXT_NODE

  moveChildren: (newParent, oldParent) ->
    _.each(DOM.getChildNodes(oldParent), (child) ->
      newParent.appendChild(child)
    )

  # IE normalize is broken
  normalize: (node) ->
    curNode = node.firstChild
    while curNode?
      nextNode = curNode.nextSibling
      if DOM.isTextNode(curNode)
        if DOM.getText(curNode).length == 0
          DOM.removeNode(curNode)
        else if DOM.isTextNode(nextNode)
          nextNode = nextNode.nextSibling
          DOM.setText(curNode, DOM.getText(curNode) + DOM.getText(curNode.nextSibling))
      curNode = nextNode

  isIE: (maxVersion) ->
    version = document.documentMode
    return version and maxVersion >= version

  removeClass: (node, cssClass) ->
    return unless DOM.hasClass(node, cssClass)
    if node.classList?
      return node.classList.remove(cssClass)
    else if node.className?
      classArray = DOM.getClasses(node)
      classArray.splice(_.indexOf(classArray, cssClass), 1)
      node.className = classArray.join(' ')

  removeNode: (node) ->
    node.parentNode?.removeChild(node)

  resetSelect: (select, trigger = true) ->
    option = DOM.getDefaultOption(select)
    if option?
      option.selected = true
      DOM.triggerEvent(select, 'change') if trigger
    else
      select.selectedIndex = null

  selectOption: (select, option, trigger = true) ->
    value = if _.isElement(option) then option.value else option
    if value
      select.value = value
    else
      select.selectedIndex = -1  # PhantomJS
    DOM.triggerEvent(select, 'change') if trigger

  setStyles: (node, styles) ->
    styleString = _.map(styles, (style, name) ->
      return "#{name}: #{style}"
    ).join('; ') + ';'
    node.setAttribute('style', styleString)

  setText: (node, text) ->
    switch node.nodeType
      when DOM.ELEMENT_NODE
        if node.textContent?
          node.textContent = text
        else
          node.innerText = text
      when DOM.TEXT_NODE then node.data = text
      else return # Noop

  switchTag: (node, newTag) ->
    newTag = newTag.toUpperCase()
    return if node.tagName == newTag
    newNode = node.ownerDocument.createElement(newTag)
    attributes = DOM.getAttributes(node)
    this.moveChildren(newNode, node) unless DOM.VOID_TAGS[newTag]?
    node.parentNode.replaceChild(newNode, node)
    _.each(attributes, (value, name) ->
      newNode.setAttribute(name, value)
    )
    return newNode

  toggleClass: (node, className, state) ->
    state = !DOM.hasClass(node, className) unless state?
    if state
      DOM.addClass(node, className)
    else
      DOM.removeClass(node, className)

  triggerEvent: (elem, eventName, options = {}) ->
    if _.indexOf(['keypress', 'keydown', 'keyup'], eventName) < 0
      event = elem.ownerDocument.createEvent('Event')
      event.initEvent(eventName, options.bubbles, options.cancelable)
    else
      event = elem.ownerDocument.createEvent('KeyboardEvent')
      lastKeyEvent = _.clone(options)
      lastKeyEvent.which = if _.isNumber(options.key) then options.key else options.key.toUpperCase().getCharAt(0)
      if DOM.isIE(10)
        modifiers = []
        modifiers.push('Alt') if options.altKey
        modifiers.push('Control') if options.ctrlKey
        modifiers.push('Meta') if options.metaKey
        modifiers.push('Shift') if options.shiftKey
        event.initKeyboardEvent(eventName, options.bubbles, options.cancelable, elem.ownerDocument.defaultView.window, 0, 0, modifiers.join(' '), null, null)
      else
        # FF uses initKeyEvent, Webkit uses initKeyboardEvent
        initFn = if _.isFunction(event.initKeyboardEvent) then 'initKeyboardEvent' else 'initKeyEvent'
        event[initFn](eventName, options.bubbles, options.cancelable, elem.ownerDocument.defaultView.window, options.ctrlKey, options.altKey, options.shiftKey, options.metaKey, 0, 0)
    elem.dispatchEvent(event)
    lastKeyEvent = null

  unwrap: (node) ->
    ret = node.firstChild
    next = node.nextSibling
    _.each(DOM.getChildNodes(node), (child) ->
      node.parentNode.insertBefore(child, next)
    )
    DOM.removeNode(node)
    return ret

  wrap: (wrapper, node) ->
    node.parentNode.insertBefore(wrapper, node) if node.parentNode?
    wrapper.appendChild(node)
    return wrapper


module.exports = DOM
