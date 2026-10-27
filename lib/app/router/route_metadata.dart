({String title, String description}) routeMetadata(String path) {
  final section = switch (path
      .split('/')
      .where((value) => value.isNotEmpty)
      .firstOrNull) {
    'login' => (
      'Iniciar sesión',
      'Entra a Ritmo y continúa con tus hábitos, actividades y metas personales.',
    ),
    'register' => (
      'Crear cuenta',
      'Crea tu cuenta en Ritmo para construir hábitos y registrar tus logros.',
    ),
    'dashboard' => (
      'Tu progreso',
      'Consulta tu experiencia, nivel, rachas y estadísticas de cumplimiento.',
    ),
    'activities' => (
      'Tus actividades',
      'Organiza actividades únicas, diarias y semanales y registra tu progreso.',
    ),
    'projects' => (
      'Tus proyectos',
      'Divide tus proyectos en tareas y sigue el avance de cada etapa.',
    ),
    'history' => (
      'Tu historial',
      'Consulta tus cumplimientos y movimientos de experiencia por fecha y categoría.',
    ),
    'badges' => (
      'Tus insignias',
      'Explora las insignias obtenidas por tu constancia y tus logros.',
    ),
    'rewards' => (
      'Tus recompensas',
      'Consulta los títulos y elementos visuales desbloqueados por tus avances.',
    ),
    'profile' => (
      'Tu perfil',
      'Administra tu perfil, zona horaria y preferencias de Ritmo.',
    ),
    'more' => (
      'Tu espacio',
      'Accede a tus insignias, recompensas y perfil personal.',
    ),
    'loading' => (
      'Preparando tu espacio',
      'Estamos preparando tu sesión de Ritmo.',
    ),
    _ => (
      'Página no encontrada',
      'La dirección solicitada no existe. Vuelve a Ritmo para continuar.',
    ),
  };
  return (title: '${section.$1} · Ritmo', description: section.$2);
}
