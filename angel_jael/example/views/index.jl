<extend src="layout.jl">
    <block name="content">
        <i if=message != null>
            You said: {{ message }}
        </i>
        <form action="/" method="post">
            <input name="message" placeholder="Say something..." type="text" value=message>
            <br>
            <input type="submit" value="Submit">
        </form>
    </block>
</extend>