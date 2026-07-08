function closex() {
  (Default(),
    $("body").css("display", "none"),
    $.post("https://BakiTelli_bankv2/close"));
}
function Default() {
  ($(".withdrawBoxOne").css("display", "none"),
    $(".bankBoxMenu").css("display", "none"),
    $(".depositpage").css("display", "none"),
    $(".withdrawpage").css("display", "none"),
    $(".transferpage").css("display", "none"));
}
function OpenMenu(t) {
  (Default(),
    "Withdraw" == t
      ? $(".withdrawpage").css("display", "block")
      : "Deposit" == t
        ? $(".depositpage").css("display", "block")
        : "Transfer" == t
          ? $(".transferpage").css("display", "block")
          : "Main" == t && $(".bankBoxMenu").css("display", "block"));
}
function First(t, e) {
  $.post(
    "https://BakiTelli_bankv2/First",
    JSON.stringify({ typ: t, count: e }),
  );
}
function Process(t) {
  ("deposit" == t
    ? $.post(
        "https://BakiTelli_bankv2/Process",
        JSON.stringify({ typ: t, count: $("#depositCount").val() }),
      )
    : "withdraw" == t
      ? $.post(
          "https://BakiTelli_bankv2/Process",
          JSON.stringify({ typ: t, count: $("#withdrawCount").val() }),
        )
      : $.post(
          "https://BakiTelli_bankv2/Process",
          JSON.stringify({
            typ: t,
            count: $("#CountTransfer").val(),
            id: $("#idTransfer").val(),
          }),
        ),
    OpenMenu("Main"));
}
(console.log("discord.gg/debux | Tebex : debux.tebex.io"),
  window.addEventListener("message", function (t) {
    "openmenu" == t.data.action
      ? ($(".amountBox").empty(),
        $("body").css("display", "block"),
        Default(),
        "mainPage" == t.data.typ && $(".bankBoxMenu").css("display", "block"))
      : "Update" == t.data.action &&
        "mainPage" == t.data.typ &&
        ($(".userTitle").html(t.data.info.name),
        $(".bankingBalanceNumber").html("$" + t.data.info.money),
        $(".banksNumber").html("$" + t.data.info.money),
        $(".amountBox").empty(),
        getTotalValueLastFiveDays(t.data.info.history),
        addHistory(t.data.info.history));
  }),
  $(document).on("keydown", function (t) {
    if (27 === t.keyCode) closex();
  }));
let histimg = null,
  histlabel = null;
function addHistory(t) {
  for (var e = 0; e < t.length; e++)
    ("withdraw" == t[e].typ
      ? ((histimg = "withdraw-icon.png"), (histlabel = "Withdraw"))
      : "deposit" == t[e].typ
        ? ((histimg = "deposit-icon.png"), (histlabel = "Deposit"))
        : ("transfer" == t[e].typ || "transferadded" == t[e].typ) &&
          ((histimg = "transfer-icon.png"), (histlabel = "Transfer")),
      (html =
        '\n      <div class="typeDepositBox">\n    <div class="typeMenu">\n      <div class="depositBoxOne">\n        <div class="depositImgTwo">\n          <div class="typeImg" style="background-image:url(./img/' +
        histimg +
        ')"></div>\n        </div>\n        <div class="depositTitleTwo">\n          Type <br /><span>' +
        histlabel +
        '</span>\n        </div>\n      </div>\n      <div class="timeBox">\n        <div class="timeTitle">\n          Time <br /><span>' +
        unixtotime(t[e].time) +
        '</span>\n        </div>\n      </div>\n      <div class="amountBoxOne">\n        <div class="amountTitle">\n          Amount <br /><span>$' +
        t[e].amount +
        "</span>\n        </div>\n      </div>\n    </div>\n  </div>\n  "),
      $(".amountBox").prepend(html));
}
function unixtotime(t) {
  let e = new Date(t),
    n = e.getFullYear(),
    a = e.getMonth() + 1,
    s = e.getDate();
  return e.getHours() + ":" + e.getMinutes() + " / " + s + "." + a + "." + n;
}
let d1Count = 0,
  d2Count = 0,
  d3Count = 0,
  d4Count = 0,
  d5Count = 0,
  d6Count = 0;
function getTotalValueLastFiveDays(t) {
  ((d1Count = 0),
    (d2Count = 0),
    (d3Count = 0),
    (d4Count = 0),
    (d5Count = 0),
    (d6Count = 0));
  for (var e = new Date(), n = 0; n < t.length; n++) {
    let a = new Date(t[n].time);
    e.getMonth() + 1 == a.getMonth() + 1 &&
      e.getFullYear() == a.getFullYear() &&
      (e.getDate() == a.getDate()
        ? "withdraw" == t[n].typ || "transfer" == t[n].typ
          ? (d1Count -= Number(t[n].amount))
          : ("deposit" != t[n].typ && "transferadded" != t[n].typ) ||
            (d1Count += Number(t[n].amount))
        : e.getDate() - 1 == a.getDate()
          ? "withdraw" == t[n].typ || "transfer" == t[n].typ
            ? (d2Count -= Number(t[n].amount))
            : ("deposit" != t[n].typ && "transferadded" != t[n].typ) ||
              (d2Count += Number(t[n].amount))
          : e.getDate() - 2 == a.getDate()
            ? "withdraw" == t[n].typ || "transfer" == t[n].typ
              ? (d3Count -= Number(t[n].amount))
              : ("deposit" != t[n].typ && "transferadded" != t[n].typ) ||
                (d3Count += Number(t[n].amount))
            : e.getDate() - 3 == a.getDate()
              ? "withdraw" == t[n].typ || "transfer" == t[n].typ
                ? (d4Count -= Number(t[n].amount))
                : ("deposit" != t[n].typ && "transferadded" != t[n].typ) ||
                  (d4Count += Number(t[n].amount))
              : e.getDate() - 4 == a.getDate()
                ? "withdraw" == t[n].typ || "transfer" == t[n].typ
                  ? (d5Count -= Number(t[n].amount))
                  : ("deposit" != t[n].typ && "transferadded" != t[n].typ) ||
                    (d5Count += Number(t[n].amount))
                : e.getDate() - 5 == a.getDate() &&
                  ("withdraw" == t[n].typ || "transfer" == t[n].typ
                    ? (d6Count -= Number(t[n].amount))
                    : ("deposit" != t[n].typ && "transferadded" != t[n].typ) ||
                      (d6Count += Number(t[n].amount))));
  }
  UpdateStatics();
}
function UpdateStatics() {
  ($(".number1 .StaticText").html("$" + Math.abs(d1Count) + "<p></p>"),
    $(".number2 .StaticText").html("$" + Math.abs(d2Count) + "<p></p>"),
    $(".number3 .StaticText").html("$" + Math.abs(d3Count) + "<p></p>"),
    $(".number4 .StaticText").html("$" + Math.abs(d4Count) + "<p></p>"),
    $(".number5 .StaticText").html("$" + Math.abs(d5Count) + "<p></p>"),
    $(".number6 .StaticText").html("$" + Math.abs(d6Count) + "<p></p>"),
    0 == d1Count ||
      (d1Count >= 1
        ? ($(".number1 .StaticText").css("color", "#94E158"),
          $(".number1 .StaticText p").css("background", "#94E158"),
          $(".number1 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #94E158",
          ))
        : ($(".number1 .StaticText").css("color", "#E15858"),
          $(".number1 .StaticText p").css("background", "#E15858"),
          $(".number1 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #E15858",
          ))),
    0 == d2Count ||
      (d2Count >= 1
        ? ($(".number2 .StaticText").css("color", "#94E158"),
          $(".number2 .StaticText p").css("background", "#94E158"),
          $(".number2 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #94E158",
          ))
        : ($(".number2 .StaticText").css("color", "#E15858"),
          $(".number2 .StaticText p").css("background", "#E15858"),
          $(".number2 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #E15858",
          ))),
    0 == d3Count ||
      (d3Count >= 1
        ? ($(".number3 .StaticText").css("color", "#94E158"),
          $(".number3 .StaticText p").css("background", "#94E158"),
          $(".number3 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #94E158",
          ))
        : ($(".number3 .StaticText").css("color", "#E15858"),
          $(".number3 .StaticText p").css("background", "#E15858"),
          $(".number3 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #E15858",
          ))),
    0 == d4Count ||
      (d4Count >= 1
        ? ($(".number4 .StaticText").css("color", "#94E158"),
          $(".number4 .StaticText p").css("background", "#94E158"),
          $(".number4 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #94E158",
          ))
        : ($(".number4 .StaticText").css("color", "#E15858"),
          $(".number4 .StaticText p").css("background", "#E15858"),
          $(".number4 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #E15858",
          ))),
    0 == d5Count ||
      (d5Count >= 1
        ? ($(".number5 .StaticText").css("color", "#94E158"),
          $(".number5 .StaticText p").css("background", "#94E158"),
          $(".number5 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #94E158",
          ))
        : ($(".number5 .StaticText").css("color", "#E15858"),
          $(".number5 .StaticText p").css("background", "#E15858"),
          $(".number5 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #E15858",
          ))),
    0 == d6Count ||
      (d6Count >= 1
        ? ($(".number6 .StaticText").css("color", "#94E158"),
          $(".number6 .StaticText p").css("background", "#94E158"),
          $(".number6 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #94E158",
          ))
        : ($(".number6 .StaticText").css("color", "#E15858"),
          $(".number6 .StaticText p").css("background", "#E15858"),
          $(".number6 .StaticText p").css(
            "box-shadow",
            "0px 0px 0.2vw 0px #E15858",
          ))));
}
