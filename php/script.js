document.addEventListener("DOMContentLoaded", () => {
  const fileInput = document.getElementById("fileInput");
  const fileName = document.getElementById("fileName");
  const añadirBtn = document.querySelector(".añadir-btn");
  const container = document.getElementById("clientesContainer");

  if (fileInput) {
    fileInput.addEventListener("change", leerArchivo);
  }

  if (añadirBtn) {
    añadirBtn.addEventListener("click", () => añadirCliente());
  }

  if (container) {
    container.addEventListener("click", (e) => {
      const target = e.target;
      if (target && target.classList && target.classList.contains("eliminar-btn")) {
        eliminarCliente(target);
      }
    });
  }

  if (fileInput && fileName) {
    fileInput.addEventListener("change", () => {
      fileName.textContent = fileInput.files?.[0]?.name || "Ningún archivo seleccionado";
    });
  }
});

function leerArchivo(event) {
  const file = event.target.files[0];

  if (!file) {
    alert("Por favor, selecciona un archivo.");
    return;
  }

  const reader = new FileReader();
  const extension = file.name.split(".").pop().toLowerCase();

  reader.onload = function (e) {
    try {
      if (extension === "json") {
        const clientes = JSON.parse(e.target.result);
        if (Array.isArray(clientes)) {
          cargarDatosDesdeJSON(clientes);
        } else {
          alert("El archivo JSON no tiene el formato correcto (se esperaba un array). ");
        }
      } else if (extension === "txt") {
        const content = e.target.result.trim();
        cargarDatosDesdeTXT(content);
      } else if (extension === "csv") {
        const content = e.target.result;
        cargarDatosDesdeCSV(content);
      } else {
        alert("Tipo de archivo no soportado.");
      }
    } catch (error) {
      alert("Error al procesar el archivo.");
      console.error("Error:", error);
    }
  };

  reader.readAsText(file);
}

function cargarDatosDesdeJSON(clientes) {
  const container = document.getElementById("clientesContainer");
  if (!container) return;

  container.innerHTML = "";
  clientes.forEach((cliente) => añadirCliente(cliente));
}

function cargarDatosDesdeTXT(content) {
  const lines = content.split("\n");
  const clientes = [];

  lines.forEach((line) => {
    const fields = line.split(",");

    if (fields.length === 8) {
      const cliente = {
        codcliente: fields[0].trim(),
        nombre: fields[1].trim(),
        apellidos: fields[2].trim(),
        tipo_cliente: fields[3].trim(),
        fecha: fields[4].trim(),
        codproducto: fields[5].trim(),
        codproducto_de_cliente: fields[6].trim(),
        descripcion_atributo: fields[7].trim(),
      };
      clientes.push(cliente);
    }
  });

  cargarDatosDesdeJSON(clientes);
}

function cargarDatosDesdeCSV(content) {
  Papa.parse(content, {
    header: true,
    skipEmptyLines: true,
    complete: function (results) {
      const clientes = results.data.map((row) => {
        return {
          codcliente: row.codcliente,
          nombre: row.nombre,
          apellidos: row.apellidos,
          tipo_cliente: row.tipo_cliente,
          fecha: row.fecha,
          codproducto: row.codproducto,
          codproducto_de_cliente: row.codproducto_de_cliente,
          descripcion_atributo: row.descripcion_atributo,
        };
      });

      cargarDatosDesdeJSON(clientes);
    },
    error: function (error) {
      alert("Error al procesar el archivo CSV.");
      console.error("Error:", error);
    },
  });
}

function añadirCliente(cliente = {}) {
  const container = document.getElementById("clientesContainer");
  if (!container) return;

  const nuevoCliente = document.createElement("div");
  nuevoCliente.classList.add("cliente-form");

  const tipo = cliente.tipo_cliente || "Nuevo";

  const extraTipoOption =
    tipo !== "Nuevo" && tipo !== "Recurrente" && tipo !== "VIP"
      ? `<option value="${escapeHtml(String(tipo))}" selected>${escapeHtml(String(tipo))}</option>`
      : "";

  nuevoCliente.innerHTML = `
    <div class="form-row">
      <div class="form-group">
        <label>Código Cliente:</label>
        <input type="number" name="codcliente[]" value="${escapeAttr(cliente.codcliente)}">
      </div>

      <div class="form-group">
        <label>Nombre:</label>
        <input type="text" name="nombre[]" value="${escapeAttr(cliente.nombre)}">
      </div>

      <div class="form-group">
        <label>Apellidos:</label>
        <input type="text" name="apellidos[]" value="${escapeAttr(cliente.apellidos)}">
      </div>

      <div class="form-group">
        <label>Tipo de Cliente:</label>
        <select name="tipo_cliente[]">
          ${extraTipoOption}
          <option value="Nuevo" ${tipo === "Nuevo" ? "selected" : ""}>Nuevo</option>
          <option value="Recurrente" ${tipo === "Recurrente" ? "selected" : ""}>Recurrente</option>
          <option value="VIP" ${tipo === "VIP" ? "selected" : ""}>VIP</option>
        </select>
      </div>
    </div>

    <div class="form-row">
      <div class="form-group">
        <label>Fecha:</label>
        <input type="date" name="fecha[]" value="${escapeAttr(cliente.fecha)}">
      </div>

      <div class="form-group">
        <label>Código Producto:</label>
        <input type="number" name="codproducto[]" value="${escapeAttr(cliente.codproducto)}">
      </div>

      <div class="form-group">
        <label>Código Producto de Cliente:</label>
        <input type="number" name="codproducto_de_cliente[]" value="${escapeAttr(cliente.codproducto_de_cliente)}">
      </div>

      <div class="form-group">
        <label>Descripción:</label>
        <textarea name="descripcion_atributo[]" rows="4">${escapeHtml(cliente.descripcion_atributo ?? "")}</textarea>
      </div>
    </div>

    <div class="botones">
      <button type="button" class="eliminar-btn">Eliminar</button>
    </div>
  `;

  container.appendChild(nuevoCliente);
}

function eliminarCliente(button) {
  button.closest(".cliente-form")?.remove();
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function escapeAttr(value) {
  if (value === null || value === undefined) return "";
  return escapeHtml(value);
}