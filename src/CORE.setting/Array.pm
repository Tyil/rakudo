class Array is List {
    method BIND_POS(\$n, $x is copy) {
        pir::find_method__PPs(List, 'BIND_POS')(self, $n, $x);
    }

    method at_pos(\$n) {
        self.exists($n)
          ?? pir::find_method__PPs(List, 'at_pos')(self, $n)
          !! pir::find_method__PPs(List, 'BIND_POS')(self, $n, my $x)
    }
}

