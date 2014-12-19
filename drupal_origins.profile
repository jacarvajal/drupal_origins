<?php
/**
 * @file Define the install proccess for drupal origins profile.
 */

/**
 * Implements hook_install_tasks().
 */
function drupal_origins_install_tasks() {
  $tasks = array();
  $current_task = variable_get('install_task', 'done');
  $tasks['drupal_origins_extensions_form'] = array(
    'display_name' => st('Drupal origins extensions'),
    'type' => 'form',
  );

  $tasks['drupal_origins_install_extensions'] = array(
    'display_name' => st('Install Drupal Origins extensions'),
    'type' => 'batch',    
    'display' => strpos($current_task, 'drupal_origins_') !== FALSE,
    'dfp_settings' => array(
      'dfp_unit' => 'Drupal_Origins_Install',
    ),
  );

  return $tasks;
}

/**
 * Return the Drupal origins extension step form.
 * @param $form
 * @param $form_state
 */
function drupal_origins_extensions_form($form, &$form_state) {
  $form = array();

  $extensions = _drupal_origins_get_extensions_definition();

  foreach ($extensions as $extension) {
    $extension_container = $extension->name . '_container';
    $form[$extension_container] = array(
      '#type' => 'container',
      '#attributes' => array('class' => array('extension')),
    );

    $form[$extension_container]['content'][$extension->name] = array(
      '#type' => 'checkbox',
      '#title' => $extension->info['name'],
    );

    $form[$extension_container]['content'][$extension->name . '_description'] = array(
      '#markup' => '<span>' . $extension->info['description'] . '</span>',
    );

    $form[$extension_container]['content'][$extension->name . '_modules_container'] =
      _drupal_origins_get_renderable_module_dependencies($extension);
  }

  $form['submit'] = array(
    '#type' => 'submit',
    '#value' => st('Continue'),
  );

  return $form;
}

/**
 * Implements FORM_submit().
 */
function drupal_origins_extensions_form_submit($form, &$form_state) {
  $extensions_to_install = array();
  foreach ($form_state['values'] as $key => $value) {
    if (_drupal_origins_is_valid_extension($key) && !empty($value)) {
      $extensions_to_install[] = $key;
    }
  }

  variable_set('drupal_origins_extensions', $extensions_to_install);
}

/**
 * Define the batch process to enable the extensions required.
 * @return array
 */
function drupal_origins_install_extensions() {
  $modules = variable_get('drupal_origins_extensions', array());
  $batch = array();

  if (!empty($modules)) {
    foreach ($modules as $module) {
      $operations[] = array('_drupal_origins_enable_module', array($module));
    }

    // Clear caches:
    $operations[] = array('_drupal_origins_clear_caches');
  }

  return $batch;
}

/**
 * Retrieve the drupal_origins extensions module definition.
 * @return array
 */
function _drupal_origins_get_extensions_definition() {
  $module_definitions = system_rebuild_module_data();
  $modules_filtered = array_filter($module_definitions, '_drupal_origins_filter_module_extensions');
  return $modules_filtered;
}

/**
 * Generate a rendereable array with the modules dependencies given a module info.
 * @param $module
 * @return array $render
 */
function _drupal_origins_get_renderable_module_dependencies($module) {
  $render = array(
    '#type' => 'container',
    'content' => array(
      $module->name . '_modules_header' => array(
        '#markup' => '<span>' . st('The following module will be enabled') . '</span>',
      ),
      $module->name . '_modules' => array(
        '#theme' => 'item_list',
        '#items' => $module->info['dependencies'],
      ),
    ),
    '#states' => array(
      'visible' => array(
        ':input[name="' . $module->name .'"]' => array('checked' => TRUE),
      ),
    ),
  );

  return $render;
}

/**
 * Filter the given module by if it's a drupal origins extension or not.
 * @param $module
 * @return bool
 */
function _drupal_origins_filter_module_extensions($module) {
  return _drupal_origins_is_valid_extension($module->name);
}

/**
 * Check the given extension is a valid drupal_origins extension.
 * @param $extension
 * @return bool
 */
function _drupal_origins_is_valid_extension($extension) {
   return (boolean)preg_match('/drupal_origins_/', $extension);
}

function _drupal_origins_clear_caches() {
  $context['message'] = t('@operation', array('@operation' => 'Clear caches'));
  drupal_flush_all_caches();
}

function _drupal_origins_enable_module() {
  module_enable(array($module), FALSE);
  $context['message'] = st('Installed %module module.', array('%module' => $module_name));
}
