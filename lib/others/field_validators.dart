class FieldValidators {
  FieldValidators._();

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return ("Campo obrigatório");
    }
    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(value);
    if (!emailValid) return ("E-mail inválido");
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ("Campo obrigatório");
    }
    if (value.length < 6) {
      return ("Senha precisa ter pelo menos 6 dígitos");
    }
    if (value.length > 20) {
      return ("Senha pode ter até 20 dígitos");
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return ("Campo obrigatório");
    }
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return ("Campo obrigatório");
    }
    return null;
  }
}